#include "ReShade.fxh"

//----------------------------------
// Benutzeroberfläche (UI / Parameter)
//----------------------------------

uniform int cvdType <
    ui_type = "combo";
    ui_label = "CVD Type";
    ui_items = "Protanomaly\0Deuteranomaly\0Tritanomaly\0";
> = 0;

uniform int simulationModel <
    ui_type = "combo";
    ui_label = "Simulation Model";
    ui_items = "Vienot 1999\0Brettel 1997\0";
> = 0;

uniform float severity <
    ui_type = "slider";
    ui_label = "DC1 Severity";
    ui_min = 0.0; ui_max = 10.0; ui_step = 0.1;
> = 4.0;

uniform float preserve_luma <
    ui_type = "slider";
    ui_label = "Preserve Luma";
    ui_min = 0.00; ui_max = 1.00; ui_step = 0.01;
> = 1.00;

uniform float scStrength <
    ui_type = "slider";
    ui_label = "Soft Compression Strength";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.1;
> = 1.0;

uniform float dckRG <
    ui_type = "slider";
    ui_label = "dckRG (experimental individual calibration)";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.1;
> = 1.0;

uniform float dckRB <
    ui_type = "slider";
    ui_label = "dckRB (experimental individual calibration)";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.1;
> = 1.0;

uniform float dckGB <
    ui_type = "slider";
    ui_label = "dckGB (experimental individual calibration)";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.1;
> = 1.0;

//----------------------------------
// Hilfsfunktionen (Mathematik)
//----------------------------------

float3 rgbToLms(float3 rgb)
{
    return float3(
        17.8824 * rgb.r + 43.5161 * rgb.g + 4.11935 * rgb.b,
         3.45565 * rgb.r + 27.1554 * rgb.g + 3.86714 * rgb.b,
         0.0299566 * rgb.r + 0.184309 * rgb.g + 1.46709 * rgb.b);
}

float3 lmsToRgb(float3 lms)
{
    return float3(
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

float3 applyProtanVienot(float3 lms, float sev)
{
    float3 outLms = lms;

    outLms.x =
        (1.0 - sev) * lms.x +
        sev *
        (
            2.02344 * lms.y -
            2.52580 * lms.z
        );

    return outLms;
}

float3 applyDeutanVienot(float3 lms, float sev)
{
    float3 outLms = lms;

    outLms.y =
        (1.0 - sev) * lms.y +
        sev *
        (
            0.494207 * lms.x +
            1.24827  * lms.z
        );

    return outLms;
}

float3 applyTritanVienot(float3 lms, float sev)
{
    float3 outLms = lms;

    outLms.z =
        (1.0 - sev) * lms.z +
        sev *
        (
           -0.395913 * lms.x +
            0.801109 * lms.y
        );

    return outLms;
}

float3 applyProtanBrettel(float3 lms, float sev)
{
    return applyProtanVienot(lms, sev);
}

float3 applyDeutanBrettel(float3 lms, float sev)
{
    return applyDeutanVienot(lms, sev);
}

//----------------------------------
// Brettel 1997 - Tritan
//----------------------------------

float3 applyTritanBrettel(
    float3 lms,
    float sev)
{
    float3 outLms = lms;

    if ((lms.x * 0.34478 -
         lms.y * 0.65518) >= 0.0)
    {
        // Plane 1

        outLms.z =
            (1.0 - sev) * lms.z +
            sev *
            (
                -0.00257 * lms.x +
                 0.05366 * lms.y
            );
    }
    else
    {
        // Plane 2

        outLms.z =
            (1.0 - sev) * lms.z +
            sev *
            (
                -0.06011 * lms.x +
                 0.16299 * lms.y
            );
    }

    return outLms;
}

float luminance(float3 c)
{
    return
        0.2126 * c.r +
        0.7152 * c.g +
        0.0722 * c.b;
}

//----------------------------------
// Pixel Shader
//----------------------------------

void PS_ColorCorrection(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0, out float4 fragColor : SV_Target)
{
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float3 rgb = color.rgb;

    //----------------------------------
    // DC1 with Viénot 1999
    //----------------------------------

    float sev = saturate(severity / 10.0);

    float3 lms = rgbToLms(rgb);

    float3 simulatedLms;

    if (simulationModel == 0)
    {
        // Viénot

        if (cvdType == 0)
        {
            simulatedLms =
                applyProtanVienot(
                    lms,
                    sev);
        }
        else if (cvdType == 1)
        {
            simulatedLms =
                applyDeutanVienot(
                    lms,
                    sev);
        }
        else
        {
            simulatedLms =
                applyTritanVienot(
                    lms,
                    sev);
        }
    }
    else
    {
        // Brettel (currently stub)

        if (cvdType == 0)
        {
            simulatedLms =
                applyProtanBrettel(
                    lms,
                    sev);
        }
        else if (cvdType == 1)
        {
            simulatedLms =
                applyDeutanBrettel(
                    lms,
                    sev);
        }
        else
        {
            simulatedLms =
                applyTritanBrettel(
                    lms,
                    sev);
        }
    }

    float3 simulated =
        saturate(
            lmsToRgb(
                simulatedLms));

    //----------------------------------
    // DCK18L
    //----------------------------------

    float rgb_rg = rgb.r - rgb.g;
    float rgb_rb = rgb.r - rgb.b;
    float rgb_gb = rgb.g - rgb.b;

    float sim_rg = simulated.r - simulated.g;
    float sim_rb = simulated.r - simulated.b;
    float sim_gb = simulated.g - simulated.b;

    float error_rg = rgb_rg - sim_rg;
    float error_rb = rgb_rb - sim_rb;
    float error_gb = rgb_gb - sim_gb;

    float deltaR = error_rg * dckRG + error_rb * dckRB;
    float deltaG = -error_rg * dckRG + error_gb * dckGB;
    float deltaB = -error_rb * dckRB - error_gb * dckGB;

    //----------------------------------
    // Soft Compression
    //----------------------------------

    float distR = (deltaR >= 0.0) ? max(0.0, 1.0 - rgb.r) : max(0.0, rgb.r);
    float distG = (deltaG >= 0.0) ? max(0.0, 1.0 - rgb.g) : max(0.0, rgb.g);
    float distB = (deltaB >= 0.0) ? max(0.0, 1.0 - rgb.b) : max(0.0, rgb.b);
    
    float exponent = 0.5 * scStrength;
    
    float gainR = (scStrength <= 0.0) ? 1.0 : pow(distR, exponent);
    float gainG = (scStrength <= 0.0) ? 1.0 : pow(distG, exponent);
    float gainB = (scStrength <= 0.0) ? 1.0 : pow(distB, exponent);

    //----------------------------------
    // Apply correction
    //----------------------------------

    float3 dc = rgb;

    dc.r += deltaR * gainR;
    dc.g += deltaG * gainG;
    dc.b += deltaB * gainB;

    dc = saturate(dc);

    //----------------------------------
    // Luminance preserve
    //----------------------------------

    float yOriginal = luminance(rgb);
    float yCorrected = luminance(dc);
    float deltaY = yCorrected - yOriginal;

    dc -= float3(deltaY, deltaY, deltaY) * preserve_luma;
    dc = saturate(dc);

    fragColor = float4(dc, color.a);
}

//----------------------------------
// Technik-Definition (Pipeline)
//----------------------------------

technique ColorCorrection
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_ColorCorrection;
    }
}
