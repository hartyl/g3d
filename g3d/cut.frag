varying vec2 texCoord;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, texCoord);
	if (texcolor.a < .10)
		discard;
	texcolor.a=1;

    return texcolor * color;
}
