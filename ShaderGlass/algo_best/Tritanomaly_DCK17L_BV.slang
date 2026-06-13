#version 450

#pragma parameter severity      "DC1 Severity" 3.0 0.0 10.0 0.1
#pragma parameter simulator "Brettel/Vienot" 0.0 0.0 1.0 1.0
#pragma parameter preserve_luma "Preserve Luma" 1.00 0.00 1.00 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;

    float severity;
    float simulator;
    float preserve_luma;

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
// Viénot 1999 - Tritan
//----------------------------------

vec3 applyTritanopiaVienot(
    vec3 lms,
    float severity)
{
    vec3 outLms = lms;

    outLms.z =
        (1.0 - severity) * lms.z +
        severity *
        (-0.01224 * lms.x +
          0.07203 * lms.y);

    return outLms;
}

//----------------------------------
// Brettel 1997 - Tritan
//----------------------------------

vec3 applyTritanopiaBrettel(
    vec3 lms,
    float severity)
{
    vec3 outLms = lms;

    if ((lms.x * 0.34478 -
         lms.y * 0.65518) >= 0.0)
    {
        // Plane 1

        outLms.z =
            (1.0 - severity) * lms.z +
            severity *
            (-0.00257 * lms.x +
              0.05366 * lms.y);
    }
    else
    {
        // Plane 2

        outLms.z =
            (1.0 - severity) * lms.z +
            severity *
            (-0.06011 * lms.x +
              0.16299 * lms.y);
    }

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
    // DC1 with Viénot 1999 or Brettel 1997
    //----------------------------------

    float sev =
        clamp(
            global.severity / 10.0,
            0.0,
            1.0);

    vec3 lms =
        rgbToLms(rgb);

    if (global.simulator < 0.5)
    {
        simulatedLms =
            applyTritanopiaBrettel(
                lms,
                sev);
    }
    else
    {
        simulatedLms =
            applyTritanopiaVienot(
                lms,
                sev);
    }

    vec3 simulated =
        clamp(
            lmsToRgb(simulatedLms),
            0.0,
            1.0);

    //----------------------------------
    // K17 (Koehler 17)
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

    // we only use fixed expansion of 1.0 atm
    float rg_expansion = 1.0;
    float rb_expansion = 1.0;
    float gb_expansion = 1.0;

    dc.r +=
        error_rg * global.rg_expansion +
        error_rb * global.rb_expansion;

    dc.g +=
       -error_rg * global.rg_expansion +
        error_gb * global.gb_expansion;

    dc.b +=
       -error_rb * global.rb_expansion -
        error_gb * global.gb_expansion;

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