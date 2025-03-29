#pragma language glsl3
varying vec4 screenPosition;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    return texturecolor * color * vec4(vec3(1-screenPosition.w/330),1);
}
