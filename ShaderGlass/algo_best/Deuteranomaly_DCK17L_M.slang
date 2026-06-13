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
// Machado 2009 - Deutan
//----------------------------------

vec3 applyDeuteranomaly(vec3 c, int s)
{
    vec3 o = c;

    switch(s)
    {
        case 0:
            break;

        case 1:
            o.r =  0.866435*c.r + 0.177704*c.g - 0.044139*c.b;
            o.g =  0.049567*c.r + 0.939063*c.g + 0.011370*c.b;
            o.b = -0.003453*c.r + 0.007233*c.g + 0.996220*c.b;
            break;

        case 2:
            o.r =  0.760729*c.r + 0.319078*c.g - 0.079807*c.b;
            o.g =  0.090568*c.r + 0.889315*c.g + 0.020117*c.b;
            o.b = -0.006027*c.r + 0.013325*c.g + 0.992702*c.b;
            break;

        case 3:
            o.r =  0.675425*c.r + 0.433850*c.g - 0.109275*c.b;
            o.g =  0.125303*c.r + 0.847755*c.g + 0.026942*c.b;
            o.b = -0.007950*c.r + 0.018572*c.g + 0.989378*c.b;
            break;

        case 4:
            o.r =  0.605511*c.r + 0.528560*c.g - 0.134071*c.b;
            o.g =  0.155318*c.r + 0.812366*c.g + 0.032316*c.b;
            o.b = -0.009376*c.r + 0.023176*c.g + 0.986200*c.b;
            break;

        case 5:
            o.r =  0.547494*c.r + 0.607765*c.g - 0.155259*c.b;
            o.g =  0.181692*c.r + 0.781742*c.g + 0.036566*c.b;
            o.b = -0.010410*c.r + 0.027275*c.g + 0.983136*c.b;
            break;

        case 6:
            o.r =  0.498864*c.r + 0.674741*c.g - 0.173604*c.b;
            o.g =  0.205199*c.r + 0.754872*c.g + 0.039929*c.b;
            o.b = -0.011131*c.r + 0.030969*c.g + 0.980162*c.b;
            break;

        case 7:
            o.r =  0.457771*c.r + 0.731899*c.g - 0.189670*c.b;
            o.g =  0.226409*c.r + 0.731012*c.g + 0.042579*c.b;
            o.b = -0.011595*c.r + 0.034333*c.g + 0.977261*c.b;
            break;

        case 8:
            o.r =  0.422823*c.r + 0.781057*c.g - 0.203881*c.b;
            o.g =  0.245752*c.r + 0.709602*c.g + 0.044646*c.b;
            o.b = -0.011843*c.r + 0.037423*c.g + 0.974421*c.b;
            break;

        case 9:
            o.r =  0.392952*c.r + 0.823610*c.g - 0.216562*c.b;
            o.g =  0.263559*c.r + 0.690210*c.g + 0.046232*c.b;
            o.b = -0.011910*c.r + 0.040281*c.g + 0.971630*c.b;
            break;

        default:
            o.r =  0.367322*c.r + 0.860646*c.g - 0.227968*c.b;
            o.g =  0.280085*c.r + 0.672501*c.g + 0.047413*c.b;
            o.b = -0.011820*c.r + 0.042940*c.g + 0.968881*c.b;
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
        applyDeuteranomaly(
            rgb,
            sev);

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