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

    // 2. Berechnung von Helligkeit (Max), Dunkelheit (Min) und Chroma (Delta)
    float max_val = max(rgb.r, max(rgb.g, rgb.b));
    float min_val = min(rgb.r, min(rgb.g, rgb.b));
    float delta = max_val - min_val;
    
    // SÄTTIGUNGS-SPERRE (Verhindert den Grün-Stich in Schatten und Grau)
    // Wenn max_val nahe 0 ist (Schwarz/Dunkelgrau) oder delta gegen 0 geht (Grau),
    // wird die Sättigung mathematisch 0.
    float saettigung = 0.0;
    if (max_val > 0.0) {
        saettigung = delta / max_val;
    }

    // Erzeugt einen fließenden Übergang: Erst ab einer spürbaren Buntheit greift der Filter.
    // Alles unter 15% Sättigung (Schatten, Texturen, graue Flächen) wird blockiert.
    float saettigungs_maske = smoothstep(0.15, 0.35, saettigung);

    // 3. Berechnung des Farb-Winkels im Hue-Spektrum
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
    if (abstand_zu_rot > 0.5) {
        abstand_zu_rot = 1.0 - abstand_zu_rot;
    }

    // 4. Biologische Glockenkurve (L-Zapfen-Emulation)
    float sigma = 0.12; 
    float l_zapfen_glockenkurve = exp(-(abstand_zu_rot * abstand_zu_rot) / (2.0 * sigma * sigma));

    // 5. Wavelength-Shifting mit Sättigungs-Sperre gekoppelt
    // 'shift_staerke' reguliert die Verschiebung (z.B. 0.25).
    float shift_staerke = 0.20; 
    
    // Die Verschiebung wird nur aktiv, wenn wir uns in der Rot-Glockenkurve befinden
    // UND der Pixel ausreichend gesättigt (bunt) ist.
    float rot_zu_gruen_transfer = rgb.r * shift_staerke * l_zapfen_glockenkurve * saettigungs_maske;

    vec3 rgb_verschoben = rgb;
    
    // Verschiebung injizieren: Rot bleibt stabil (kein Helligkeitsverlust),
    // Grün bekommt den spektralen Träger-Shift. Blau bleibt absolut unangetastet.
    rgb_verschoben.r = rgb.r; 
    rgb_verschoben.g = min(1.0, rgb.g + rot_zu_gruen_transfer);
    rgb_verschoben.b = rgb.b;

    // 6. Absicherung & Gamma wieder anwenden
    rgb_verschoben = clamp(rgb_verschoben, 0.0, 1.0);
    vec3 rgb_final = pow(rgb_verschoben, vec3(1.0 / 2.2));

    FragColor = vec4(rgb_final, color.a);
}