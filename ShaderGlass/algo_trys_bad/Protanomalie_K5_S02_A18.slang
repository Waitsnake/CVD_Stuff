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
    
    // 1. Linearisierung (Gamma entfernen)
    vec3 rgb = pow(color.rgb, vec3(2.2));

    // 2. Errechnung der Farb-Intensitäten
    float max_val = max(rgb.r, max(rgb.g, rgb.b));
    float min_val = min(rgb.r, min(rgb.g, rgb.b));
    float delta = max_val - min_val; // Absolute Farbreinheit (Chroma)
    
    // RAUSCH- UND SCHWARZ-FILTER (Chroma-Sperre)
    // Wenn delta unter 0.08 liegt, ist das Pixel faktisch Schwarz oder Grau.
    // Dieser Filter schneidet das Hintergrundrauschen komplett ab.
    float chroma_mask = smoothstep(0.05, 0.15, delta);

    // Relative Sättigung für die Farberkennung
    float saettigung = (max_val > 0.0) ? (delta / max_val) : 0.0;
    float saettigungs_maske = smoothstep(0.15, 0.35, saettigung);

    // 3. Farbton (Hue) bestimmen
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

    // VIOLETT-SCHUTZ (Sorgt dafür, dass kurzwelliges Violett/Blau links stabil bleibt)
    float violett_schutz = 1.0;
    if (rgb.b > rgb.g) {
        violett_schutz = max(0.0, 1.0 - (rgb.b - rgb.g) * 2.0);
    }

    // 4. SPEKTRUM-STAUCHUNG (Ziehharmonika-Effekt)
    vec3 rgb_final_linear = rgb;

    // Der Filter darf nur anspringen, wenn er in der Rot-Kurve liegt, bunte Farben hat
    // UND nicht im schwarzen Hintergrund-Rauschen liegt (chroma_mask)
    if (l_zapfen_bereich > 0.01 && saettigungs_maske > 0.0 && chroma_mask > 0.0)
    {
        // REGEL-PARAMETER FÜR DICH:
        float stauchungs_faktor = 0.20;   // Niedriger = Roter, Höher = Mehr Richtung Orange
        float aufhellung_dunkelrot = 1.8; // Höher = Stärkere Ausleuchtung des toten Spektrum-Endes

        // Nichtlineare Helligkeits-Kompression (Reagiert nur auf echtes, dunkles Spektral-Rot)
        float dunkelheits_faktor = pow(1.0 - rgb.r, 2.0);
        
        // Kombination aller Schutzmasken inklusive der neuen Chroma-Rauschsperre
        float boost = dunkelheits_faktor * aufhellung_dunkelrot * l_zapfen_bereich * saettigungs_maske * violett_schutz * chroma_mask;
        
        // Wellenlängen-Stauchung injizieren
        rgb_final_linear.r = min(1.0, rgb.r + boost * 0.7);
        rgb_final_linear.g = min(1.0, rgb.g + boost * stauchungs_faktor * 0.3); 
        rgb_final_linear.b = rgb.b;
    }

    // 5. Absicherung & Gamma wieder anwenden
    rgb_final_linear = clamp(rgb_final_linear, 0.0, 1.0);
    vec3 rgb_final = pow(rgb_final_linear, vec3(1.0 / 2.2));

    FragColor = vec4(rgb_final, color.a);
}