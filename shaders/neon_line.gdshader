shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float glow_size : hint_range(0, 50) = 10.0;
uniform float glow_intensity : hint_range(0, 1) = 0.5;

void fragment() {
    // Couleur de base de la ligne
    vec4 color = line_color;
    
    // Effet de glow en échantillonnant autour du fragment
    for (float i = 1.0; i <= glow_size; i += 1.0) {
        // Glow dans toutes les directions
        vec2 offset = vec2(i) / SCREEN_PIXEL_SIZE * 0.001;
        
        color += texture(TEXTURE, UV + vec2(offset.x, 0.0)) * glow_intensity * line_color;
        color += texture(TEXTURE, UV - vec2(offset.x, 0.0)) * glow_intensity * line_color;
        color += texture(TEXTURE, UV + vec2(0.0, offset.y)) * glow_intensity * line_color;
        color += texture(TEXTURE, UV - vec2(0.0, offset.y)) * glow_intensity * line_color;
        
        // Diagonales pour un glow plus complet
        color += texture(TEXTURE, UV + offset) * glow_intensity * line_color * 0.5;
        color += texture(TEXTURE, UV - offset) * glow_intensity * line_color * 0.5;
        color += texture(TEXTURE, UV + vec2(offset.x, -offset.y)) * glow_intensity * line_color * 0.5;
        color += texture(TEXTURE, UV - vec2(offset.x, -offset.y)) * glow_intensity * line_color * 0.5;
    }
    
    COLOR = color;
}