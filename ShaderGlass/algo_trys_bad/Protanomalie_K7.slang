#version 450

#pragma parameter kompensation "Protanomalie Kompensation" 0.50 0.0 10.0 0.01
#pragma parameter rot_shift "Rot→Gruen Verschiebung" 0.25 0.0 10.0 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    float kompensation;
    float rot_shift;
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

float gauss(float x, float mu, float sigma)
{
    float d = x - mu;
    return exp(-(d*d)/(2.0*sigma*sigma));
}

void main()
{
    vec4 color = texture(Source, vTexCoord);

    // Linearisieren
    vec3 rgb = pow(color.rgb, vec3(2.2));

    //-------------------------------------
    // Chroma / Sättigung
    //-------------------------------------

    float maxv = max(rgb.r,max(rgb.g,rgb.b));
    float minv = min(rgb.r,min(rgb.g,rgb.b));

    float delta = maxv-minv;

    float chromaMask = smoothstep(0.05,0.15,delta);

    float sat = (maxv > 0.0) ? delta/maxv : 0.0;
    float satMask = smoothstep(0.15,0.35,sat);

    //-------------------------------------
    // Hue
    //-------------------------------------

    float hue = 0.0;

    if(delta > 0.0001)
    {
        if(maxv == rgb.r)
        {
            hue = (rgb.g-rgb.b)/delta;
            if(hue < 0.0) hue += 6.0;
            hue /= 6.0;
        }
        else if(maxv == rgb.g)
        {
            hue = ((rgb.b-rgb.r)/delta + 2.0)/6.0;
        }
        else
        {
            hue = ((rgb.r-rgb.g)/delta + 4.0)/6.0;
        }
    }

    //-------------------------------------
    // Pseudo-Wellenlänge
    //-------------------------------------

    float lambda = 650.0 - hue * 250.0;

    //-------------------------------------
    // Gesunder L-Zapfen
    //-------------------------------------

    float L_normal =
        gauss(lambda,565.0,45.0);

    //-------------------------------------
    // Verschobener L-Zapfen
    //-------------------------------------

    float shift_nm =
        15.0 * global.kompensation;

    float L_anom =
        gauss(lambda,565.0-shift_nm,45.0);

    //-------------------------------------
    // Wahrnehmungsverlust
    //-------------------------------------

    float coneDiff =
        max(0.0,L_normal-L_anom);

    //-------------------------------------
    // Blau-Schutz
    //-------------------------------------

    float violetProtect = 1.0;

    if(rgb.b > rgb.g)
    {
        violetProtect =
            max(0.0,
                1.0 -
                (rgb.b-rgb.g)*2.0);
    }

    //-------------------------------------
    // Endgewichtung
    //-------------------------------------

    float weight =
        coneDiff *
        chromaMask *
        satMask *
        violetProtect;

    //-------------------------------------
    // Rotenergie
    //-------------------------------------

    float boost =
        rgb.r *
        weight;

    //-------------------------------------
    // Rot -> Grün Shift
    //-------------------------------------

    vec3 outRgb = rgb;

    outRgb.r =
        min(1.0,
            rgb.r +
            boost*0.50);

    outRgb.g =
        min(1.0,
            rgb.g +
            boost *
            global.rot_shift);

    //-------------------------------------

    outRgb =
        clamp(outRgb,0.0,1.0);

    outRgb =
        pow(outRgb,
            vec3(1.0/2.2));

    FragColor =
        vec4(outRgb,color.a);
}