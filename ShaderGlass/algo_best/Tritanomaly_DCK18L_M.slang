#version 450

#pragma parameter severity      "DC1 Severity" 3.0 0.0 10.0 0.1
#pragma parameter preserve_luma "Preserve Luma" 1.00 0.00 1.00 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;

    float severity;
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
// Machado 2009 - Tritan
//----------------------------------

vec3 applyTritanomaly(vec3 c, int s)
{
    vec3 o = c;

    switch(s)
    {
        case 0:
            break;

        case 1:
            o.r =  0.926670*c.r + 0.092514*c.g - 0.019184*c.b;
            o.g =  0.021191*c.r + 0.964503*c.g + 0.014306*c.b;
            o.b =  0.008437*c.r + 0.054813*c.g + 0.936750*c.b;
            break;

        case 2:
            o.r =  0.895720*c.r + 0.133330*c.g - 0.029050*c.b;
            o.g =  0.029997*c.r + 0.945400*c.g + 0.024603*c.b;
            o.b =  0.013027*c.r + 0.104707*c.g + 0.882266*c.b;
            break;

        case 3:
            o.r =  0.905871*c.r + 0.127791*c.g - 0.033662*c.b;
            o.g =  0.026856*c.r + 0.941251*c.g + 0.031893*c.b;
            o.b =  0.013410*c.r + 0.148296*c.g + 0.838294*c.b;
            break;

        case 4:
            o.r =  0.948035*c.r + 0.089490*c.g - 0.037526*c.b;
            o.g =  0.014364*c.r + 0.946792*c.g + 0.038844*c.b;
            o.b =  0.010853*c.r + 0.193991*c.g + 0.795156*c.b;
            break;

        case 5:
            o.r =  1.017277*c.r + 0.027029*c.g - 0.044306*c.b;
            o.g = -0.006113*c.r + 0.958479*c.g + 0.047634*c.b;
            o.b =  0.006379*c.r + 0.248708*c.g + 0.744913*c.b;
            break;

        case 6:
            o.r =  1.104996*c.r - 0.046633*c.g - 0.058363*c.b;
            o.g = -0.032137*c.r + 0.971635*c.g + 0.060503*c.b;
            o.b =  0.001336*c.r + 0.317922*c.g + 0.680742*c.b;
            break;

        case 7:
            o.r =  1.193214*c.r - 0.109812*c.g - 0.083402*c.b;
            o.g = -0.058496*c.r + 0.979410*c.g + 0.079086*c.b;
            o.b = -0.002346*c.r + 0.403492*c.g + 0.598854*c.b;
            break;

        case 8:
            o.r =  1.257728*c.r - 0.139648*c.g - 0.118081*c.b;
            o.g = -0.078003*c.r + 0.975409*c.g + 0.102594*c.b;
            o.b = -0.003316*c.r + 0.501214*c.g + 0.502102*c.b;
            break;

        case 9:
            o.r =  1.278864*c.r - 0.125333*c.g - 0.153531*c.b;
            o.g = -0.084748*c.r + 0.957674*c.g + 0.127074*c.b;
            o.b = -0.000989*c.r + 0.601151*c.g + 0.399838*c.b;
            break;

        default:
            o.r =  1.255528*c.r - 0.076749*c.g - 0.178779*c.b;
            o.g = -0.078411*c.r + 0.930809*c.g + 0.147602*c.b;
            o.b =  0.004733*c.r + 0.691367*c.g + 0.303900*c.b;
            break;
    }

    return o;
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
    // DC1 with Machado 2009
    //----------------------------------

    int sev =
        int(
            clamp(
                floor(global.severity + 0.5),
                0.0,
                10.0));

    vec3 simulated =
        applyTritanomaly(
            rgb,
            sev);

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
    // DCK factors
    //----------------------------------

    float dckRG = 1.0;
    float dckRB = 1.0;
    float dckGB = 1.0;

    //----------------------------------
    // Soft Compression
    //----------------------------------

    float rgGain = 1.0;
    float rbGain = 1.0;
    float gbGain = 1.0;

    float rgDelta = abs(error_rg * dckRG);
    float rbDelta = abs(error_rb * dckRB);
    float gbDelta = abs(error_gb * dckGB);

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
        error_rg * dckRG * rgGain +
        error_rb * dckRB * rbGain;

    dc.g +=
       -error_rg * dckRG * rgGain +
        error_gb * dckGB * gbGain;

    dc.b +=
       -error_rb * dckRB * rbGain -
        error_gb * dckGB * gbGain;

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