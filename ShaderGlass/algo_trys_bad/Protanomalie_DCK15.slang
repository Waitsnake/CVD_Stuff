#version 450

#pragma parameter severity "DC1 Severity" 5.0 0.0 10.0 0.1
#pragma parameter rot_expansion "K15 Expansion" 0.15 0.0 1.0 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    float severity;
    float rot_expansion;
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

    if(s >= 10)
    {
        o.r = 0.152286*c.r + 1.052583*c.g - 0.204868*c.b;
        o.g = 0.114503*c.r + 0.786281*c.g + 0.099216*c.b;
        o.b = -0.003882*c.r - 0.048116*c.g + 1.051998*c.b;
    }

    return o;
}

void main()
{
    vec4 color = texture(Source, vTexCoord);

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
        clamp(dc,0.0,1.0);

    //----------------------------------
    // K15
    //----------------------------------

    float mixRG =
        max(
            0.0,
            dc.r - dc.g);

    float shift =
        mixRG *
        global.rot_expansion;

    dc.r =
        min(
            1.0,
            dc.r + shift);

    dc.g =
        max(
            0.0,
            dc.g - shift);

    FragColor =
        vec4(dc,color.a);
}