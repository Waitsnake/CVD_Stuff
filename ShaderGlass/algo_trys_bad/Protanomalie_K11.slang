#version 450

#pragma parameter aufhellung_dunkelrot "Aufhellung Dunkelrot" 0.5 0.0 5.0 0.1
#pragma parameter rot_expansion "Rot Expansion" 0.6 0.0 3.00 0.01
#pragma parameter rx_gamma "RX Gamma" 1.8 1.0 10.0 0.05

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    float aufhellung_dunkelrot;
    float rot_expansion;
    float rx_gamma;
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

void main()
{
    vec4 color = texture(Source, vTexCoord);

    //------------------------------------
    // Linearraum
    //------------------------------------

    vec3 rgb = pow(color.rgb, vec3(2.2));

    //------------------------------------
    // Chroma / Saturation
    //------------------------------------

    float maxv = max(rgb.r,max(rgb.g,rgb.b));
    float minv = min(rgb.r,min(rgb.g,rgb.b));

    float delta = maxv-minv;

    float chromaMask =
        smoothstep(0.05,0.15,delta);

    float sat =
        (maxv > 0.0)
        ? delta/maxv
        : 0.0;

    float satMask =
        smoothstep(0.15,0.35,sat);

    //------------------------------------
    // Hue
    //------------------------------------

    float hue = 0.0;

    if(delta > 0.001)
    {
        if(maxv == rgb.r)
        {
            hue = (rgb.g-rgb.b)/delta;

            if(hue < 0.0)
                hue += 6.0;

            hue /= 6.0;
        }
        else if(maxv == rgb.g)
        {
            hue =
                ((rgb.b-rgb.r)/delta + 2.0)
                / 6.0;
        }
        else
        {
            hue =
                ((rgb.r-rgb.g)/delta + 4.0)
                / 6.0;
        }
    }

    //------------------------------------
    // Originale Rotmaske
    //------------------------------------

    float distToRed = hue;

    if(distToRed > 0.5)
        distToRed = 1.0-distToRed;

    float redMask =
        exp(
            -(distToRed*distToRed)
            /(2.0*0.12*0.12)
        );

    //------------------------------------
    // Violettschutz
    //------------------------------------

    float violetProtect = 1.0;

    if(rgb.b > rgb.g)
    {
        violetProtect =
            max(
                0.0,
                1.0-(rgb.b-rgb.g)*2.0
            );
    }

    //------------------------------------
    // ASACR Boost
    //------------------------------------

    float boost =
        rgb.r *
        global.aufhellung_dunkelrot *
        redMask *
        satMask *
        chromaMask *
        violetProtect;

    vec3 outRgb = rgb;

    outRgb.r =
        min(
            1.0,
            rgb.r + boost*0.7
        );

    //------------------------------------
    // K11 RX Gamma
    //------------------------------------

    float redGreenMix =
        min(outRgb.r,outRgb.g);

    redGreenMix =
        pow(
            redGreenMix,
            global.rx_gamma
        );

    float rxMask =
        redMask *
        satMask *
        chromaMask;

    float shift =
        redGreenMix *
        global.rot_expansion *
        rxMask;

    outRgb.r =
        min(
            1.0,
            outRgb.r + shift
        );

    outRgb.g =
        max(
            0.0,
            outRgb.g - shift
        );

    //------------------------------------

    outRgb =
        clamp(outRgb,0.0,1.0);

    vec3 finalRgb =
        pow(
            outRgb,
            vec3(1.0/2.2)
        );

    FragColor =
        vec4(finalRgb,color.a);
}