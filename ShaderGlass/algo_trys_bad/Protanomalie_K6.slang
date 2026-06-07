#version 450

// Adaptives Spektrales Amplituden-Chroma-Remapping (Adaptive Spectral Amplitude and Chroma Remapping) 

// 1. PARAMETER-EXPORT FÜR DAS SHADERGLASS-UI MENÜ
#pragma parameter aufhellung_dunkelrot "Aufhellung Dunkelrot" 1.6 0.0 3.0 0.1
#pragma parameter stauchungs_faktor    "Stauchung / Orange-Shift" 0.0 0.0 1.0 0.05

// 2. DAS INTERNE SLANG-MENÜ-LAYOUT (Zwingende RetroArch-Vorgabe für Regler)
layout(std140, set = 0, binding = 0) uniform UBO 
{ 
    mat4 MVP; 
    float aufhellung_dunkelrot;
    float stauchungs_faktor;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
void main() { gl_Position = global.MVP * Position; vTexCoord = TexCoord; }

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
    vec4 color = texture(Source, vTexCoord);
    
    // Linealisierung (Gamma entfernen)
    vec3 rgb = pow(color.rgb, vec3(2.2));

    // Errechnung der Farb-Intensitäten
    float max_val = max(rgb.r, max(rgb.g, rgb.b));
    float min_val = min(rgb.r, min(rgb.g, rgb.b));
    float delta = max_val - min_val;
    
    // Rauschsperre für den schwarzen Hintergrund
    float chroma_mask = smoothstep(0.05, 0.15, delta);

    // Relative Sättigung
    float saettigung = (max_val > 0.0) ? (delta / max_val) : 0.0;
    float saettigungs_maske = smoothstep(0.15, 0.35, saettigung);

    // Farbton (Hue) bestimmen
    float hue = 0.0;
    if (delta > 0.001) {
        if (max_val == rgb.r) {
            hue = (rgb.g - rgb.b) / delta;
            if (hue < 0.0) hue += 6.0;
            hue = hue / 6.0;
        } else if (max_val == rgb.g) {
            hue = ((rgb.b - rgb.r) / delta + 2.0) / 6.0;
        } else {
            hue = ((rgb.r - rgb.g) / delta + 4.0) / 6.0;
        }
    }

    float abstand_zu_rot = hue;
    if (abstand_zu_rot > 0.5) abstand_zu_rot = 1.0 - abstand_zu_rot;

    // Biologische Glockenkurve des L-Zapfens
    float l_zapfen_bereich = exp(-(abstand_zu_rot * abstand_zu_rot) / (2.0 * 0.12 * 0.12));

    // Violett-Schutz für die linke Seite des Spektrums
    float violett_schutz = 1.0;
    if (rgb.b > rgb.g) {
        violett_schutz = max(0.0, 1.0 - (rgb.b - rgb.g) * 2.0);
    }

    // Spektrum-Anhebung
    vec3 rgb_final_linear = rgb;

    if (l_zapfen_bereich > 0.01 && saettigungs_maske > 0.0 && chroma_mask > 0.0)
    {
        // Biologischer Fade-Out über das Original-Rot
        float biologischer_fade = rgb.r;
        
        // ZUWEISUNG GEFIXT: Die Variablen hängen nun direkt am "global."-Präfix des Menü-Blocks
        float boost = biologischer_fade * global.aufhellung_dunkelrot * l_zapfen_bereich * saettigungs_maske * violett_schutz * chroma_mask;
        
        // Push und Verrechnung der interaktiven Werte aus dem GUI-Menü
        rgb_final_linear.r = min(1.0, rgb.r + boost * 0.7);
        rgb_final_linear.g = min(1.0, rgb.g + boost * global.stauchungs_faktor * 0.3); 
        rgb_final_linear.b = rgb.b;
    }

    // Absicherung & Gamma wieder anwenden
    rgb_final_linear = clamp(rgb_final_linear, 0.0, 1.0);
    vec3 rgb_final = pow(rgb_final_linear, vec3(1.0 / 2.2));

    FragColor = vec4(rgb_final, color.a);
}