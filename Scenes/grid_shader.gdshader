shader_type canvas_item;

uniform vec4 grid_color : source_color = vec4(0.3, 0.3, 0.3, 0.5);
uniform vec4 background_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float cell_size : hint_range(1, 1000) = 50.0;
uniform float line_width : hint_range(0.1, 10.0) = 1.0;

void fragment() {
    vec2 uv = UV / TEXTURE_PIXEL_SIZE;
    
    // Calcul des positions de grille
    vec2 grid_pos = floor(uv / cell_size);
    vec2 grid_uv = fract(uv / cell_size);
    
    // Dessin des lignes
    vec2 line = smoothstep(vec2(line_width / cell_size), vec2(0.0), grid_uv);
    line += smoothstep(vec2(1.0 - line_width / cell_size), vec2(1.0), grid_uv);
    
    float grid = max(line.x, line.y);
    
    // Mélange entre couleur de grille et fond
    COLOR = mix(background_color, grid_color, grid);
}