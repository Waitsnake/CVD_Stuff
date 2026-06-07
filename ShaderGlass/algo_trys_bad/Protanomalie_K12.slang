#version 450

#pragma parameter aufhellung_dunkelrot "Aufhellung Dunkelrot" 0.5 0.0 5.0 0.1
#pragma parameter rot_expansion "Rot Expansion" 0.6 0.0 3.0 0.01
#pragma parameter rx_blur "RX Blur" 1.0 0.0 20.0 0.05

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    float aufhellung_dunkelrot;
    float rot_expansion;
    float rx_blur;
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

float redWeight(vec3 rgb)
{
    float maxv = max(rgb.r,max(rgb.g,rgb.b));
    float minv = min(rgb.r,min(rgb.g,rgb.b));

    float delta = maxv - minv;

    if(delta < 0.001)
        return 0.0;

    float hue = 0.0;

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

    float distToRed = hue;

    if(distToRed > 0.5)
        distToRed = 1.0-distToRed;

    float redMask =
        exp(
            -(distToRed*distToRed)
            /(2.0*0.12*0.12)
        );

    float sat =
        (maxv > 0.0)
        ? delta/maxv
        : 0.0;

    float satMask =
        smoothstep(0.15,0.35,sat);

    float chromaMask =
        smoothstep(0.05,0.15,delta);

    return redMask * satMask * chromaMask;
}

void main()
{
    vec4 color = texture(Source, vTexCoord);

    vec3 rgb =
        pow(color.rgb, vec3(2.2));

    //------------------------------------
    // Hauptanalyse
    //------------------------------------

    float maxv =
        max(rgb.r,max(rgb.g,rgb.b));

    float minv =
        min(rgb.r,min(rgb.g,rgb.b));

    float delta =
        maxv-minv;

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
    // Dunkelrot-Aufhellung
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
    // K12 RX Blur
    //------------------------------------

    vec2 texel =
        global.rx_blur /
        vec2(textureSize(Source,0));

    float rxCenter =
        redWeight(rgb);

    float rxLeft =
        redWeight(
            pow(
                texture(
                    Source,
                    vTexCoord + vec2(-texel.x,0)
                ).rgb,
                vec3(2.2)
            )
        );

    float rxRight =
        redWeight(
            pow(
                texture(
                    Source,
                    vTexCoord + vec2(texel.x,0)
                ).rgb,
                vec3(2.2)
            )
        );

    float rxUp =
        redWeight(
            pow(
                texture(
                    Source,
                    vTexCoord + vec2(0,-texel.y)
                ).rgb,
                vec3(2.2)
            )
        );

    float rxDown =
        redWeight(
            pow(
                texture(
                    Source,
                    vTexCoord + vec2(0,texel.y)
                ).rgb,
                vec3(2.2)
            )
        );

    float rxMask =
        (
            rxCenter +
            rxLeft +
            rxRight +
            rxUp +
            rxDown
        ) / 5.0;

    //------------------------------------
    // Expansion
    //------------------------------------

    float redGreenMix =
        min(
            outRgb.r,
            outRgb.g
        );

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