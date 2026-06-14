#version 450

#pragma parameter severity      "DC1 Severity" 3.0 0.0 10.0 0.1
#pragma parameter preserve_luma "Preserve Luma" 1.00 0.00 1.00 0.01
#pragma parameter dckRG  "dckRG (experimental individual calibration)" 1.0 -2.0 2.0 0.1
#pragma parameter dckRB  "dckRB (experimental individual calibration)" 1.0 -2.0 2.0 0.1
#pragma parameter dckGB  "dckGB (experimental individual calibration)" 1.0 -2.0 2.0 0.1

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;

    float severity;
    float preserve_luma;
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
// Viénot 1999 - Protan
//----------------------------------

vec3 applyProtanopiaVienot(
    vec3 lms,
    float severity)
{
    vec3 outLms = lms;

    outLms.x =
        (1.0 - severity) * lms.x +
        severity *
        (2.02344 * lms.y -
         2.52580 * lms.z);

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
        applyProtanopiaVienot(
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

    float sim_rg = simulated.r - simulated.g;
    float sim_rb = simulated.r - simulated.b;
    float sim_gb = simulated.g - simulated.b;

    float rgb_rg = rgb.r - rgb.g;
    float rgb_rb = rgb.r - rgb.b;
    float rgb_gb = rgb.g - rgb.b;

    float error_rg = rgb_rg - sim_rg;
    float error_rb = rgb_rb - sim_rb;
    float error_gb = rgb_gb - sim_gb;

    vec3 dc = rgb;

    //----------------------------------
    // Soft Compression
    //----------------------------------

    float rgGain = 1.0;
    float rbGain = 1.0;
    float gbGain = 1.0;

    float rgDelta = abs(error_rg * global.dckRG);
    float rbDelta = abs(error_rb * global.dckRB);
    float gbDelta = abs(error_gb * global.dckGB);

    //----------------------------------
    // RG
    //----------------------------------

    if (rgDelta > 1e-6)
    {
        if (error_rg > 0.0)
        {
            rgGain =
                min(
                    (1.0 - rgb.r) / rgDelta,
                    rgb.g / rgDelta);
        }
        else
        {
            rgGain =
                min(
                    rgb.r / rgDelta,
                    (1.0 - rgb.g) / rgDelta);
        }

        rgGain =
            clamp(
                rgGain,
                0.0,
                1.0);
    }

    //----------------------------------
    // RB
    //----------------------------------

    if (rbDelta > 1e-6)
    {
        if (error_rb > 0.0)
        {
            rbGain =
                min(
                    (1.0 - rgb.r) / rbDelta,
                    rgb.b / rbDelta);
        }
        else
        {
            rbGain =
                min(
                    rgb.r / rbDelta,
                    (1.0 - rgb.b) / rbDelta);
        }

        rbGain =
            clamp(
                rbGain,
                0.0,
                1.0);
    }

    //----------------------------------
    // GB
    //----------------------------------

    if (gbDelta > 1e-6)
    {
        if (error_gb > 0.0)
        {
            gbGain =
                min(
                    (1.0 - rgb.g) / gbDelta,
                    rgb.b / gbDelta);
        }
        else
        {
            gbGain =
                min(
                    rgb.g / gbDelta,
                    (1.0 - rgb.b) / gbDelta);
        }

        gbGain =
            clamp(
                gbGain,
                0.0,
                1.0);
    }

    //----------------------------------
    // Apply DCK18 correction
    //----------------------------------

    dc.r +=
        error_rg * global.dckRG * rgGain +
        error_rb * global.dckRB * rbGain;

    dc.g +=
       -error_rg * global.dckRG * rgGain +
        error_gb * global.dckGB * gbGain;

    dc.b +=
       -error_rb * global.dckRB * rbGain -
        error_gb * global.dckGB * gbGain;

    dc =
        clamp(
            dc,
            0.0,
            1.0);

    //----------------------------------
    // L (luminance preserve)
    //----------------------------------

    float yOriginal =
        luminance(rgb);

    float yCorrected =
        luminance(dc);

    float deltaY =
        yCorrected -
        yOriginal;

    dc -=
        vec3(deltaY) *
        global.preserve_luma;

    dc =
        clamp(
            dc,
            0.0,
            1.0);

    //----------------------------------

    FragColor =
        vec4(
            dc,
            color.a);
}