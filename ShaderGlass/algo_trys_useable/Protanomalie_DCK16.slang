#version 450

#pragma parameter severity      "DC1 Severity" 1.0 0.0 10.0 0.1
#pragma parameter rg_expansion  "RG Expansion" 0.40 -2.0 2.0 0.01
#pragma parameter rb_expansion  "RB Expansion" 0.15 -2.0 2.0 0.01
#pragma parameter gb_expansion  "GB Expansion" 0.00 -2.0 2.0 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    float severity;
    float rg_expansion;
    float rb_expansion;
    float gb_expansion;
} global;

#pragma stage vertex

layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;

vec3 applyProtanomaly(vec3 c, int s)
{
    vec3 o = c;

    switch(s)
    {
        case 0: break;

        case 1:
            o.r =  0.856167*c.r + 0.182038*c.g - 0.038205*c.b;
            o.g =  0.029342*c.r + 0.955115*c.g + 0.015544*c.b;
            o.b = -0.002880*c.r - 0.001563*c.g + 1.004443*c.b;
            break;

        case 2:
            o.r =  0.734766*c.r + 0.334872*c.g - 0.069637*c.b;
            o.g =  0.051840*c.r + 0.919198*c.g + 0.028963*c.b;
            o.b = -0.004928*c.r - 0.004209*c.g + 1.009137*c.b;
            break;

        case 3:
            o.r =  0.630323*c.r + 0.465641*c.g - 0.095964*c.b;
            o.g =  0.069181*c.r + 0.890046*c.g + 0.040773*c.b;
            o.b = -0.006308*c.r - 0.007724*c.g + 1.014032*c.b;
            break;

        case 4:
            o.r =  0.539009*c.r + 0.579343*c.g - 0.118352*c.b;
            o.g =  0.082546*c.r + 0.866121*c.g + 0.051332*c.b;
            o.b = -0.007136*c.r - 0.011959*c.g + 1.019095*c.b;
            break;

        case 5:
            o.r =  0.458064*c.r + 0.679578*c.g - 0.137642*c.b;
            o.g =  0.092785*c.r + 0.846313*c.g + 0.060902*c.b;
            o.b = -0.007494*c.r - 0.016807*c.g + 1.024301*c.b;
            break;

        case 6:
            o.r =  0.385450*c.r + 0.769005*c.g - 0.154455*c.b;
            o.g =  0.100526*c.r + 0.829802*c.g + 0.069673*c.b;
            o.b = -0.007442*c.r - 0.022190*c.g + 1.029632*c.b;
            break;

        case 7:
            o.r =  0.319627*c.r + 0.849633*c.g - 0.169261*c.b;
            o.g =  0.106241*c.r + 0.815969*c.g + 0.077790*c.b;
            o.b = -0.007025*c.r - 0.028051*c.g + 1.035076*c.b;
            break;

        case 8:
            o.r =  0.259411*c.r + 0.923008*c.g - 0.182420*c.b;
            o.g =  0.110296*c.r + 0.804340*c.g + 0.085364*c.b;
            o.b = -0.006276*c.r - 0.034346*c.g + 1.040622*c.b;
            break;

        case 9:
            o.r =  0.203876*c.r + 0.990338*c.g - 0.194214*c.b;
            o.g =  0.112975*c.r + 0.794542*c.g + 0.092483*c.b;
            o.b = -0.005222*c.r - 0.041043*c.g + 1.046265*c.b;
            break;

        default:
            o.r =  0.152286*c.r + 1.052583*c.g - 0.204868*c.b;
            o.g =  0.114503*c.r + 0.786281*c.g + 0.099216*c.b;
            o.b = -0.003882*c.r - 0.048116*c.g + 1.051998*c.b;
            break;
    }

    return o;
}

void main()
{
    vec4 color =
        texture(Source, vTexCoord);

    vec3 rgb = color.rgb;

    //----------------------------------
    // DC1
    //----------------------------------

    int sev =
        int(clamp(
            floor(global.severity + 0.5),
            0.0,
            10.0));

    vec3 simulated =
        applyProtanomaly(
            rgb,
            sev);

    vec3 error =
        rgb - simulated;

    vec3 dc;

    dc.r =
        rgb.r +
        0.7 * error.r;

    dc.g =
        rgb.g +
        0.4 * error.r +
        error.g;

    dc.b =
        rgb.b +
        0.1 * error.r +
        error.b;

    dc =
        clamp(
            dc,
            0.0,
            1.0
        );

    //----------------------------------
    // K16
    //----------------------------------

    float rg =
        dc.r - dc.g;

    float rb =
        dc.r - dc.b;

    float gb =
        dc.g - dc.b;

    dc.r +=
        rg * global.rg_expansion +
        rb * global.rb_expansion;

    dc.g +=
       -rg * global.rg_expansion +
        gb * global.gb_expansion;

    dc.b +=
       -rb * global.rb_expansion -
        gb * global.gb_expansion;

    //----------------------------------

    dc =
        clamp(
            dc,
            0.0,
            1.0
        );

    FragColor =
        vec4(
            dc,
            color.a
        );
}