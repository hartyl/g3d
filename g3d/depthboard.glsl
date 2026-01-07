// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen

#ifdef VERTEX
varying vec2 texCoord;
attribute vec4 InstancePosition;
uniform lowp mat4 projectionMatrix; // handled by the camera
uniform mat3 viewMatrix;       // handled by the camera

// uniform vec3 cameraUp;
//uniform vec3 cameraForward;
// uniform vec3 cameraPos;
// uniform vec2 cameraRight;

uniform vec3 translation;
// uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec3 worldPosition;
varying vec3 viewPosition;
varying vec4 screenPosition;
varying vec3 cameraForward;
// varying vec3 vertexNormal;
// varying vec4 vertexColor;
// uniform mat4 modelMatrix;      // models send their own model matrices when drawn

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
	// worldPosition += vec4(vertexPosition.x,vertexPosition.y,vertexPosition.z,0);
	// float cosPitch = sin(cameraRight.z);
	// vec3 cameraUp = vec3(cameraRight.y*cosPitch,-cameraRight.x*cosPitch,-cos(cameraRight.z));
	// vec3 cameraForward = -cross(vec3(cameraRight.xy,0), cameraUp);
    cameraForward = normalize(InstancePosition.xyz + translation);
	vec3 cameraRight = normalize(cross(cameraForward, vec3(0,0,1)));
	vec3 cameraUp = -cross(cameraForward,cameraRight);
	worldPosition = cameraUp * vertexPosition.y;
	worldPosition += cameraRight * vertexPosition.x;
	// worldPosition.xy *= worldPosition.z + 2;
	// worldPosition = viewMatrix * worldPosition;
	worldPosition -= cameraForward * vertexPosition.z;
	viewPosition = viewMatrix * (InstancePosition.xyz + translation + worldPosition * (InstancePosition.w+1));
	// viewPosition.xy -= vertexPosition.xy * (InstancePosition.w+1);
    screenPosition = projectionMatrix * vec4(viewPosition,1);
	// texCoord = worldPosition.xy;
	texCoord = vertexPosition.xy;

    // save some data from this vertex for use in fragment shaders
    // vertexNormal = VertexNormal;
    // vertexColor = VertexColor;

    // for some reason models are flipped vertically when rendering to a canvas
    // so we need to detect when this is being rendered to a canvas, and flip it back

    return screenPosition;
}
#endif
#ifdef PIXEL
varying vec3 worldPosition;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(tex, worldPosition.xy/2+.5);
	if (texcolor.a < .5)
		discard;
    return texcolor * color;
}
#endif
