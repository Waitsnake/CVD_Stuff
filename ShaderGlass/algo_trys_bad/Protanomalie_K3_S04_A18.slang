#version 450

layout(std140, set = 0, binding = 0) uniform UBO { mat4 MVP; } global;

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
    
    // 1. Linealisierung (Gamma entfernen)
    vec3 rgb = pow(color.rgb, vec3(2.2));

    // 2. Berechnung des Farbtons (Hue) und der Sättigung
    float max_val = max(rgb.r, max(rgb.g, rgb.b));
    float min_val = min(rgb.r, min(rgb.g, rgb.b));
    float delta = max_val - min_val;
    
    float saettigung = (max_val > 0.0) ? (delta / max_val) : 0.0;
    float saettigungs_maske = smoothstep(0.15, 0.35, saettigung);

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

    // Abstand zu reinem Rot (0.0 / 1.0) im Farbkreis berechnen
    float abstand_zu_rot = hue;
    if (abstand_zu_rot > 0.5) abstand_zu_rot = 1.0 - abstand_zu_rot;

    // 3. SPEKTRUM-STAUCHUNG (Das Ziehharmonika-Prinzip)
    vec3 rgb_final_linear = rgb;

    // Biologische Glockenkurve des L-Zapfens (Breite = 0.12)
    float l_zapfen_bereich = exp(-(abstand_zu_rot * abstand_zu_rot) / (2.0 * 0.12 * 0.12));

    if (l_zapfen_bereich > 0.01 && saettigungs_maske > 0.0)
    {
        // -------------------------------------------------------------
        // REGEL-PARAMETER FÜR DICH:
        float stauchungs_faktor = 0.40;   // Niedriger = Roter, Höher = Mehr Richtung Orange
        float aufhellung_dunkelrot = 1.8; // Setze auf 0.0 für den "0-Effekt" (Original-Desktop)
        // -------------------------------------------------------------

        // Nichtlineare Helligkeits-Kompression für die dunklen Rot-Anteile
        float dunkelheits_faktor = pow(1.0 - rgb.r, 2.0);
        float boost = dunkelheits_faktor * aufhellung_dunkelrot * l_zapfen_bereich * saettigungs_maske;
        
        // Wellenlängen-Stauchung: Verschiebung im Frequenzraum
        rgb_final_linear.r = min(1.0, rgb.r + boost * 0.7);
        rgb_final_linear.g = min(1.0, rgb.g + boost * stauchungs_faktor * 0.3); 
        rgb_final_linear.b = rgb.b;
    }

    // 4. Absicherung & Gamma wieder anwenden
    rgb_final_linear = clamp(rgb_final_linear, 0.0, 1.0);
    vec3 rgb_final = pow(rgb_final_linear, vec3(1.0 / 2.2));

    FragColor = vec4(rgb_final, color.a);
}