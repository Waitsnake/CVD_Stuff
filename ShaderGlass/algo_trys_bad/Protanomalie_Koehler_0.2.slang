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
    
    // 1. Linearisierung (Gamma entfernen für exakte Kurvenberechnung)
    vec3 rgb = pow(color.rgb, vec3(2.2));

    // 2. Berechnung des Farb-Winkels im Hue-Spektrum (Farbkreis)
    // Wir nutzen eine RGB-zu-Farbton-Approximation, um die Position im Spektrum zu bestimmen.
    // Reines Rot liegt bei 0.0. Gelb/Grün wandert Richtung 0.3, Blau liegt bei 0.6.
    float max_val = max(rgb.r, max(rgb.g, rgb.b));
    float min_val = min(rgb.r, min(rgb.g, rgb.b));
    float delta = max_val - min_val;
    
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

    // Da der Farbkreis bei Rot (1.0 und 0.0) zusammenläuft, korrigieren wir den Abstand zu reinem Rot
    float abstand_zu_rot = hue;
    if (abstand_zu_rot > 0.5) {
        abstand_zu_rot = 1.0 - abstand_zu_rot;
    }

    // 3. Die biologische Glockenkurve (Gauß-Verteilung)
    // Wir nutzen die eulersche Funktion: f(x) = e^(-(x^2) / (2 * sigma^2))
    // 'sigma' bestimmt die Breite der Glockenkurve des L-Zapfens.
    // Ein Wert von 0.12 lässt die Kurve sanft über Orange bis an die Grenze von Grün fließen.
    float sigma = 0.12; 
    float l_zapfen_glockenkurve = exp(-(abstand_zu_rot * abstand_zu_rot) / (2.0 * sigma * sigma));

    // 4. Kontinuierliches Wavelength-Shifting innerhalb der Glockenkurve
    // 'shift_staerke' bestimmt, wie weit die Wellenlängen zusammengeschoben werden (z.B. 620nm -> 610nm).
    float shift_staerke = 0.20; 
    
    // Die Verschiebung wird fließend mit der Stärke der Glockenkurve multipliziert
    float rot_zu_gruen_transfer = rgb.r * shift_staerke * l_zapfen_glockenkurve;

    vec3 rgb_verschoben = rgb;
    
    // Verschiebung anwenden: Nur der Rot-Anteil triggert die Verschiebung,
    // wandert fließend in den Grün-Kanal (Kurven-Stauchung nach links).
    // Blau bleibt isoliert und unberührt, da die Glockenkurve dort gegen Null läuft.
    rgb_verschoben.r = rgb.r; 
    rgb_verschoben.g = min(1.0, rgb.g + rot_zu_gruen_transfer);
    rgb_verschoben.b = rgb.b;

    // 5. Absicherung vor Übersteuerung & Gamma wieder anwenden
    rgb_verschoben = clamp(rgb_verschoben, 0.0, 1.0);
    vec3 rgb_final = pow(rgb_verschoben, vec3(1.0 / 2.2));

    FragColor = vec4(rgb_final, color.a);
}