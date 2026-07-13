// Unlit + transparency + URP + VR support
Shader "Condensation URP"
{
	SubShader 
	{
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		float _Cutoff;
		float4 _Color;
		CBUFFER_END
		ENDHLSL

		Pass
		{
			Name "Unlit"
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma shader_feature _ALPHATEST_ON
			
			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);

			struct Attributes 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				float3 normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				float4 screenPos : TEXCOORD1;
				float3 normal : NORMAL;
				float3 worldPos : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			// 1D -> 3D pseudo-random
			float3 Hash13(float value)
			{
				float3 p = frac((float3)(value) * float3(0.1031, 0.11369, 0.13787));
				p += dot(p, p.yzx + 19.19);
				return frac(float3((p.x + p.y) * p.z, (p.x + p.z) * p.y, (p.y + p.z) * p.x));
			}

			// 1D -> 4D pseudo-random
			float4 Hash14(float value)
			{
				return frac(sin(value * float4(123.0, 1024.0, 1456.0, 264.0)) * float4(6547.0, 345.0, 8799.0, 1564.0));
			}

			// Simple scalar noise
			float Noise(float value)
			{
				return frac(sin(value * 12345.564) * 7658.76);
			}

			// Saw-like temporal curve
			float Saw(float edge, float time)
			{
				return smoothstep(0.0, edge, time) * smoothstep(1.0, edge, time);
			}

			// Dynamic Rain Layer, returns: x = drop mask, y = trail mask
			float2 RainLayer(float2 uv, float time)
			{
				float2 originalUV = uv;
				uv.y += time * 0.3; // Falling motion
				float2 cellScale = float2(6.0, 1.0); // Grid configuration
				float2 gridScale = cellScale * 2.0;
				float2 cellID = floor(uv * gridScale); // Current cell
				float columnOffset = Noise(cellID.x); // Offset each column independently
				uv.y += columnOffset;
				cellID = floor(uv * gridScale); // Recalculate cell after offset
				float3 rnd = Hash13(cellID.x * 35.2 + cellID.y * 2376.1); // Random values per cell
				float2 localUV = frac(uv * gridScale) - float2(0.5, 0.0);  // Local coordinates inside cell
				float dropX = rnd.x - 0.5; // Drop position
				float waveY = originalUV.y * 20.0; // Horizontal wiggle while falling
				float wiggle = sin(waveY + sin(waveY));
				dropX += wiggle * (0.5 - abs(dropX)) * (rnd.z - 0.5);
				dropX *= 0.7;
				float lifeTime = frac(time * 0.25 + rnd.z); // Animated vertical movement
				float dropY = (Saw(0.85, lifeTime) - 0.5) * 0.9 + 0.5;
				float2 dropPos = float2(dropX, dropY);
				float distToDrop = length((localUV - dropPos) * cellScale.yx);
				float mainDrop = smoothstep(0.4, 0.0, distToDrop);
				float trailFade = sqrt(smoothstep(1.0, dropY, localUV.y));
				float trailDistance = abs(localUV.x - dropX);
				float trail = smoothstep(0.23 * trailFade, 0.15 * trailFade * trailFade, trailDistance);
				float trailFront = smoothstep(-0.02, 0.02, localUV.y - dropY);
				trail *= trailFront * trailFade * trailFade;
				float y = originalUV.y;
				float smallTrail = smoothstep(0.2 * trailFade, 0.0, trailDistance);
				float droplets = max(0.0, (sin(y * (1.0 - y) * 120.0) - localUV.y)) * smallTrail * trailFront * rnd.z; 
				y = frac(y * 10.0) + (localUV.y - 0.5); // Random droplet distribution
				float dropletDist = length(localUV - float2(dropX, y));
				droplets = smoothstep(0.3, 0.0, dropletDist);
				float mask = mainDrop + droplets * trailFade * trailFront;
				return float2(mask, trail);
			}

			float StaticDrops(float2 uv, float time)
			{
				uv *= 60.0;
				float2 cellID = floor(uv);
				uv = frac(uv) - 0.5;
				float3 rnd = Hash13(cellID.x * 107.45 + cellID.y * 3543.654);
				float2 dropPos = (rnd.xy - 0.5) * 0.7;
				float dist = length(uv - dropPos);
				float fade = Saw(0.025, frac(time + rnd.z));
				return smoothstep(0.3, 0.0, dist) * frac(rnd.z * 10.0) * fade;
			}

			// Combined rain system, returns: x = combined mask, y = combined trail
			float2 Rain(float2 uv, float time, float staticWeight, float layer1Weight,float layer2Weight)
			{
				float staticLayer = StaticDrops(uv, time) * staticWeight;
				float2 layer1 = RainLayer(uv, time) * layer1Weight;
				float2 layer2 = RainLayer(uv * 1.85, time) * layer2Weight;
				float combinedMask = staticLayer + layer1.x + layer2.x;
				combinedMask = smoothstep(0.3, 1.0, combinedMask);
				float combinedTrail = max(layer1.y * staticWeight, layer2.y * layer1Weight);
				return float2(combinedMask, combinedTrail);
			}

			float4 Condensation(float2 uv, float4 screenPos)
			{
				float globalTime = _Time.g;
				float rainTime = globalTime * 0.2;
				float rainAmount = sin(globalTime * 0.05) * 0.3 + 0.7;
				float staticWeight = smoothstep(-0.5, 1.0, rainAmount) * 2.0;
				float layer1Weight = smoothstep(0.25, 0.75, rainAmount);
				float layer2Weight = smoothstep(0.0, 0.5, rainAmount);
				float2 rain = Rain(uv, rainTime, staticWeight, layer1Weight,layer2Weight);
				float2 offset = float2(0.001, 0.0);
				float sampleX = Rain(uv + offset, rainTime, staticWeight, layer1Weight, layer2Weight).x;
				float sampleY = Rain(uv + offset.yx, rainTime, staticWeight, layer1Weight, layer2Weight).x;
				float2 normal = float2(sampleX - rain.x, sampleY - rain.x);
				float baseFog = 0.15;
				float alpha = baseFog + rain.x * 0.55 + rain.y * 0.1;
				return float4(float3(normal, 0.0) + float3(0.7, 0.7, 0.7), alpha);
			}	
	
			Varyings VSMain(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				OUT.screenPos = ComputeScreenPos(OUT.vertex);
				OUT.normal = IN.normal;
				OUT.worldPos = TransformObjectToWorld(IN.vertex.xyz);
				return OUT;
			}

			float4 PSMain(Varyings IN) : SV_Target
			{
				float2 uv = IN.uv.xy;
				float3 normal = normalize(IN.normal);
				clip(0.9 - abs(normal.y));
				float4 condensation = Condensation(uv, IN.screenPos);
				float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos);
				float3 dropNormal = normalize(float3(condensation.r - 0.7, condensation.g - 0.7, 1.0));
				float3 reflDirection = reflect(-viewDir, dropNormal);
				float3 reflection = GlossyEnvironmentReflection(reflDirection, 0.0, 1.0);
				float3 color = lerp(float3(0.7,0.7,0.7), reflection.rgb, condensation.r * 0.75);				
				return float4(color, condensation.a);
			}
			ENDHLSL
		}
	}
}