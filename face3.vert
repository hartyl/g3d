#pragma language glsl3
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_bit_encoding : enable
// written by groverbuger for g3d
// september 2021
// MIT license
// rewritten by hartyl for a voxel engine
// march 2025

// uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas
uniform ivec3 translation;
uniform uint CHUNK_SIZE;
uniform int coorPos;
uniform int bitsPerD;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute highp uint InstancePosition;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 screenPosition;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
	uint p = InstancePosition >> coorPos;
    screenPosition = 
	// transpose
	(viewMatrix)
	* vec4(
		vertexPosition.x + translation.x + (p & CHUNK_SIZE),
		vertexPosition.y + translation.y + ((p>>bitsPerD) & CHUNK_SIZE),
		vertexPosition.z + translation.z + (p>>bitsPerD>>bitsPerD),
		vertexPosition.w);

	// if (screenPosition.x>screenPosition.z || screenPosition.x<-screenPosition.z || screenPosition.y>screenPosition.z || screenPosition.y<-screenPosition.z) return vec4(0);
    return screenPosition;
}
