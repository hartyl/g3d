#pragma language glsl3
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_bit_encoding : enable
// written by groverbuger for g3d
// september 2021
// MIT license
// rewritten by hartyl for a voxel engine
// march 2025

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas
uniform vec3 translation;
uniform int CHUNK_SIZE;
uniform int coorPos;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute highp uint InstancePosition;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 screenPosition;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
	int p = int(InstancePosition >> coorPos);
	vec4 pos = vec4(mod(p,CHUNK_SIZE),mod(p/CHUNK_SIZE,CHUNK_SIZE),p/(CHUNK_SIZE*CHUNK_SIZE),0);
    screenPosition = projectionMatrix * viewMatrix * (vertexPosition + pos + vec4(translation*CHUNK_SIZE,0));

    return screenPosition;
}
