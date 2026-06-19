#version 450

#pragma parameter severity      "DC1 Severity" 3.0 0.0 10.0 0.1
#pragma parameter preserve_luma "Preserve Luma" 1.00 0.00 1.00 0.01
#pragma parameter scStrength "Soft Compression Strength" 1.0 0.0 5.0 0.1
#pragma parameter dckRG  "dckRG (experimental individual calibration)" 1.0 -2.0 2.0 0.1
#pragma parameter dckRB  "dckRB (experimental individual calibration)" 1.0 -2.0 2.0 0.1
#pragma parameter dckGB  "dckGB (experimental individual calibration)" 1.0 -2.0 2.0 0.1

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;

    float severity;
    float preserve_luma;
	float scStrength;
	float dckRG;
    float dckRB;
    float dckGB;

} global;

#pragma stage vertex

layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position =
        global.MVP * Position;

    vTexCoord =
        TexCoord;
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;

//----------------------------------
// RGB <-> LMS
//----------------------------------

vec3 rgbToLms(vec3 rgb)
{
    return vec3(
        17.8824 * rgb.r + 43.5161 * rgb.g + 4.11935 * rgb.b,
         3.45565 * rgb.r + 27.1554 * rgb.g + 3.86714 * rgb.b,
         0.0299566 * rgb.r + 0.184309 * rgb.g + 1.46709 * rgb.b);
}

vec3 lmsToRgb(vec3 lms)
{
    return vec3(
         0.0809444479 * lms.x +
        -0.1305044090 * lms.y +
         0.1167210660 * lms.z,

        -0.0102485335 * lms.x +
         0.0540193266 * lms.y +
        -0.1136147080 * lms.z,

        -0.000365296938 * lms.x +
        -0.00412161469  * lms.y +
         0.6935114050   * lms.z);
}

//----------------------------------
// Viénot 1999 - Deutan
//----------------------------------

vec3 applyDeuteranopiaVienot(
    vec3 lms,
    float severity)
{
    vec3 outLms = lms;

    outLms.y =
        (1.0 - severity) * lms.y +
        severity *
        (0.49421 * lms.x +
         1.24827 * lms.z);

    return outLms;
}

float luminance(vec3 c)
{
    return
        0.2126 * c.r +
        0.7152 * c.g +
        0.0722 * c.b;
}

void main()
{
    vec4 color =
        texture(
            Source,
            vTexCoord);

    vec3 rgb =
        color.rgb;

    //----------------------------------
    // DC1 with Viénot 1999
    //----------------------------------

    float sev =
        clamp(
            global.severity / 10.0,
            0.0,
            1.0);

    vec3 lms =
        rgbToLms(rgb);

    vec3 simulatedLms =
        applyDeuteranopiaVienot(
            lms,
            sev);

    vec3 simulated =
        clamp(
            lmsToRgb(simulatedLms),
            0.0,
            1.0);

    //----------------------------------
    // DCK18L
    //----------------------------------

    //----------------------------------
    // 1) Original channel differences
    //----------------------------------

    float rgb_rg = rgb.r - rgb.g;
    float rgb_rb = rgb.r - rgb.b;
    float rgb_gb = rgb.g - rgb.b;

    //----------------------------------
    // 2) Simulated channel differences
    //----------------------------------

    float sim_rg = simulated.r - simulated.g;
    float sim_rb = simulated.r - simulated.b;
    float sim_gb = simulated.g - simulated.b;

    //----------------------------------
    // 3) Information loss
    //----------------------------------

    float error_rg = rgb_rg - sim_rg;
    float error_rb = rgb_rb - sim_rb;
    float error_gb = rgb_gb - sim_gb;


    //----------------------------------
    // 4) DCK17 correction
    //----------------------------------

    float deltaR =
        error_rg * global.dckRG +
        error_rb * global.dckRB;

    float deltaG =
       -error_rg * global.dckRG +
        error_gb * global.dckGB;

    float deltaB =
       -error_rb * global.dckRB -
        error_gb * global.dckGB;

    //----------------------------------
    // 5) Soft Compression
    //----------------------------------

    float distR =
        (deltaR >= 0.0)
        ? max(0.0, 1.0 - rgb.r)
        : max(0.0, rgb.r);

    float distG =
        (deltaG >= 0.0)
        ? max(0.0, 1.0 - rgb.g)
        : max(0.0, rgb.g);
    
    float distB =
        (deltaB >= 0.0)
        ? max(0.0, 1.0 - rgb.b)
        : max(0.0, rgb.b);
    
    float exponent =
        0.5 * global.scStrength;
    
    float gainR =
        (global.scStrength <= 0.0)
        ? 1.0
        : pow(distR, exponent);
    
    float gainG =
        (global.scStrength <= 0.0)
        ? 1.0
        : pow(distG, exponent);
    
    float gainB =
        (global.scStrength <= 0.0)
        ? 1.0
        : pow(distB, exponent);

    //----------------------------------
    // 6) Apply correction
    //----------------------------------

    vec3 dc = rgb;

    dc.r +=
        deltaR * gainR;

    dc.g +=
        deltaG * gainG;

    dc.b +=
        deltaB * gainB;

    dc =
        clamp(
            dc,
            0.0,
            1.0);

    //----------------------------------
    // 7) Adaptive Luminance Preserve (DCK19L)
    //----------------------------------

    float yOriginal =
        luminance(
            rgb);

    float yCorrected =
        luminance(
            dc);

    float deltaY =
        yCorrected -
        yOriginal;

    //----------------------------------
    // Visibility of color separation
    //----------------------------------

    float visibility =
        length(
            vec3(
                error_rg,
                error_rb,
                error_gb));

    //----------------------------------
    // Normalize visibility
    //----------------------------------

    visibility /=
        1.7320508;

    //----------------------------------
    // Adaptive LP
    //----------------------------------

    float adaptiveLP =
        global.preserve_luma *
        (1.0 +
         visibility);

    //----------------------------------
    // Apply adaptive LP
    //----------------------------------

    dc.rgb -=
        vec3(
            deltaY,
            deltaY,
            deltaY) *
        adaptiveLP;

    dc.rgb =
        clamp(
            dc.rgb,
            0.0,
            1.0);
    //----------------------------------


    FragColor =
        vec4(
            dc,
            color.a);
}