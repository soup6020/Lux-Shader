/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


const float persistance = 0.7;
const float lacunarity = 1.5;
float CloudNoise(vec2 coord, vec2 wind)
{
	float retValue = 0.0;

	float amplitude = 1.0;
	float frequency = 0.45;

	for (int i = 0; i < 7; i++)
	{
		retValue += texture2D(noisetex, (coord + wind * 0.4 * pow(frequency, 0.3)) * frequency).r * amplitude;
		frequency *= lacunarity;
		amplitude *= persistance;
	}

	return retValue * 9.0;
}

float CloudCoverage(float noise, float cosT, float coverage)
{
	float noiseMix = mix(noise, 21.0, 0.33 * rainStrength);
	float noiseFade = clamp(sqrt(cosT * 10.0), 0.0, 1.0);
	float noiseCoverage = ((coverage * coverage) + CLOUD_AMOUNT);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return max(noiseMix * noiseFade - noiseCoverage, 0.0) * multiplier;
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol)
{
	float cosT = dot(normalize(viewPos), upVec);
	float cosS = dot(normalize(viewPos), sunVec);

	if (cosT < 0.1) return vec4(0.0);

	#if AA == 2
	dither = fract(16.0 * frameTimeCounter + dither);
	#endif

	float cloud = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.1667;
	float colorMultiplier = CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	float noiseMultiplier = CLOUD_THICKNESS * 0.2;
	float scattering = pow(cosS * 0.6 * (2.0 * sunVisibility - 1.0) + 0.5, 4.0);

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.001,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.002
	) * CLOUD_HEIGHT / 15.0;

	vec3 cloudColor = vec3(0.0);
	vec3 worldPos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);

	for (int i = 0; i < 6; i++) 
	{
		if (cloud > 0.99) break;

		vec3 planeCoord = worldPos * ((CLOUD_HEIGHT + (i + dither) * 1.3) / worldPos.y) * 0.004;
		vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;
		float coverage = float(i - 3.0 + dither) * 0.667;

		float noise = CloudNoise(coord * 0.1, wind * 0.6);
		noise = CloudCoverage(noise, cosT, coverage) * noiseMultiplier;
		noise /= 10.0 + noise;

		cloudGradient = mix(
			cloudGradient,
			mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
			noise * (1.0 - cloud * cloud)
		);
		
		cloud = mix(cloud, 1.0, noise);
		gradientMix += 0.1667;
	}

	if (cloud < 0.005) return vec4(0.0);

	cloudColor = mix(
		ambientCol * 0.5 * (0.5 * sunVisibility + 0.5),
		lightCol * (1.0 + scattering),
		cloudGradient * cloud
	);
	
	cloudColor *= 1.0 - 0.6 * rainStrength;
	cloud *= sqrt(sqrt(clamp(cosT * 10.0 - 1.0, 0.0, 1.0))) * (1.0 - 0.6 * rainStrength);

	return vec4(cloudColor * colorMultiplier, cloud * cloud * CLOUD_OPACITY);
}