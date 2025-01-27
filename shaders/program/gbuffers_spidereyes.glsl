/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Settings
#include "/lib/settings.glsl"

// Fragment Shader
#ifdef FSH

// Varyings
varying vec2 texCoord;

// Uniforms
uniform sampler2D texture;

float Luma(vec3 color) 
{
 	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

// Program
void main()
{
    vec4 albedo = texture2D(texture, texCoord);
	
	// Entity Eye Recoloring
	albedo.rgb /= Luma(albedo.rgb) * 2.0;

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
	
    #ifdef WHITE_WORLD
	albedo.rgb = vec3(2.0);
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifdef MATERIAL_SUPPORT
	/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
	#endif
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying vec2 texCoord;

// Uniforms
#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

#ifdef WORLD_CURVATURE
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
#endif

// Includes
#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

// Program
void main()
{
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	#ifdef WORLD_CURVATURE
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.y -= WorldCurvature(position.xz);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
	#endif
	
	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif