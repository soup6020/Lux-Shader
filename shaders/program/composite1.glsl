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

varying vec3 sunVec, upVec;

// Uniforms
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float far;
uniform float near;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

// Optifine Constants
const bool colortex1MipmapEnabled = true;

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

// Includes
#include "/lib/color/lightColor.glsl"
#include "/lib/color/endColor.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/borderFog.glsl"

// Program
void main()
{
    vec4 color = texture2D(colortex0, texCoord.xy);
	vec3 vl = texture2D(colortex1, texCoord.xy).rgb;
	float z0 = texture2D(depthtex0, texCoord).r;
	float vlVisibilityMult = VOLUMETRIC_FOG_STRENGTH * (1.0 - rainStrength * eBS * 0.875) * shadowFade * (1.0 - blindFactor);

	#if defined(OVERWORLD) || defined(BORDER_FOG)
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	#endif

	#ifdef OVERWORLD
	vec3 sky = GetSkyColor(viewPos.xyz, lightCol);
	float cosS = dot(normalize(viewPos.xyz), sunVec);
	vl *= mix(sky, lightCol, exp2(-(1.0 - cosS) * 7.0) * sunVisibility * 0.5);
	#endif

	#ifdef END
    vl *= endCol.rgb * 0.025;
	#endif

	color.rgb += vl * vlVisibilityMult;

	#ifdef BORDER_FOG
	if (isEyeInWater != 1) 
	{
		vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		bool hasBorderFog = false;
		float borderFogFactor = GetBorderFogMixFactor(eyePlayerPos, far, z0, hasBorderFog);

		if (hasBorderFog) 
		{
			#ifdef OVERWORLD
			// TODO: Does not work at night time
			// vec3 borderFogColor = mix(sky, vec3(max(eBS, 0.007)), 1.0 - eBS * eBS);
			color.rgb = mix(color.rgb, sky, borderFogFactor);
			#endif

			#ifdef END
			// TODO
			// color.rgb = mix(color.rgb, endCol.rgb, borderFogFactor);
			#endif
		}
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying vec2 texCoord;

varying vec3 sunVec, upVec;

// Uniforms
uniform float timeAngle;

uniform mat4 gbufferModelView;

// Program
void main()
{
	texCoord = gl_MultiTexCoord0.xy;	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
}

#endif