Shader "Procedural Flame URP"
{
	Properties
	{
        [NoScaleOffset] _Hash("RGBA Noise Medium", 2D) = "black" {}
		_Variant ("Variant", Range (0,8)) = 2
		_Speed ("Speed", Range (0,5)) = 1
		_Color ("Color", Vector) = (1.3, 1.3, 1, 1)	
		_FlameHeight("Flame Height", Range(0.1, 2.0)) = 1.0	
		_SmokeAmount("Smoke Amount", Range(0.0, 1.0)) = 0.75
		_SmokeDensity("Smoke Density", Range(0.5, 4.0)) = 2.0		
	}
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
		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		float _Cutoff;
		float4 _Color;
		float _Variant;
		float _Speed;
		float _FlameHeight;
		float _SmokeAmount;
		float _SmokeDensity;
		sampler2D _Hash;
		CBUFFER_END
		ENDHLSL

		Pass
		{
			Name "Unlit"
			Blend One OneMinusSrcAlpha
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma shader_feature _ALPHATEST_ON

			struct Attributes 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float2 Hash(float2 p)
			{
				p = float2(dot(p, float2(127.1, 311.7)),dot(p, float2(269.5, 183.3)));
				return frac(sin(p) * 43758.5453123) * 2.0 - 1.0;
			}
			
			/*float2 Hash(float2 p)
			{
				float2 uv = (floor(p) + 0.5) / 256.0;
				return tex2Dlod(_Hash, float4(uv,0,0)).rg * 2.0 - 1.0;
			}*/

			float Noise(float2 p)
			{
				const float SKEW = 0.366025404;    
				const float UNSKEW = 0.211324865;
				float2 cell = floor(p + (p.x + p.y) * SKEW);
				float2 localPos = p - cell + (cell.x + cell.y) * UNSKEW;
				float2 simplexOffset = (localPos.x > localPos.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
				float2 corner1 = localPos - simplexOffset + UNSKEW;
				float2 corner2 = localPos - 1.0 + 2.0 * UNSKEW;
				float3 attenuation = max(0.5 - float3(dot(localPos, localPos),dot(corner1, corner1), dot(corner2, corner2)),0.0);
				attenuation *= attenuation;
				attenuation *= attenuation;
				float3 gradients = float3(dot(localPos, Hash(cell)),dot(corner1, Hash(cell + simplexOffset)),dot(corner2, Hash(cell + 1.0)));
				return dot(attenuation * gradients, float3(70.0, 70.0, 70.0));
			}
			
			float Fbm(float2 uv)
			{
				const float2x2 OCTAVE_MATRIX = float2x2(1.6,  1.2, -1.2,  1.6);
				float value = 0.0;
				float amplitude = 0.5;
				for (int i = 0; i < 4; i++)
				{
					value += amplitude * Noise(uv);
					uv = mul(OCTAVE_MATRIX, uv);
					amplitude *= 0.5;
				}
				return value * 0.5 + 0.5;
			}

			float4 Flame(float2 uv)
			{
				float flameIndex = floor(_Variant);
				float2 flameUV = uv * float2(5.0, 2.0);
				float column = floor(flameUV.x);
				float targetColumn = 2.0;
				if (column != targetColumn)
				{
					return (float4)(0.0);
				}
				float2 localUV = float2(frac(flameUV.x),flameUV.y);
				localUV.x = localUV.x - 0.5;
				localUV.y -= 0.25;
				float strength = flameIndex;
				float timeOffset = max(3.0, strength * 1.25) * _Time.g * _Speed;
				float2 noiseUV = strength * localUV  - float2(0.0, timeOffset);
				float flameNoise = Fbm(noiseUV);
				float2 flameShape = localUV * float2(1.8 + localUV.y * 1.5, 0.75);
				float distanceField = length(flameShape) - flameNoise * max(0.0, localUV.y + 0.25);
				float flameMask = 1.0 - 16.0 * pow(max(0.0, distanceField), 1.2);
				float intensity = flameNoise * flameMask * (_FlameHeight - pow(2.5 * uv.y, 4.0));
				intensity = clamp(intensity, 0.0, 1.0);
				float3 flameColor = float3(_Color.r * intensity, _Color.g * intensity, pow(intensity * _Color.b, 9.0)); 
				float secondaryNoise = Fbm(strength * localUV * 1.25 - float2(0.0, timeOffset));
				float3 smokeColor = pow((float3)(1.0 - clamp(intensity, -1.0, 0.0)) * secondaryNoise * secondaryNoise, (float3)(_SmokeDensity));
				float blendFactor = _SmokeAmount - dot(flameColor, float3(1.0,1.0,1.0)) / 3.0;
				flameColor = lerp(flameColor, smokeColor, blendFactor);
				flameColor = saturate(flameColor);
				float alpha = flameMask * saturate(1.0 - pow(uv.y / _FlameHeight, 3.0));
				clip(alpha - 0.001);
				return float4(lerp((float3)(0.0), flameColor, alpha), alpha);
			}
				
			Varyings VSMain(Attributes IN)
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				float3 worldPos = TransformObjectToWorld(float3(0,0,0));
				float3 forward = normalize(_WorldSpaceCameraPos - worldPos);
				float3 right = normalize(cross(float3(0,1,0), forward));
				float3 up = float3(0,1,0);
				float3 objectScale = float3(length(unity_ObjectToWorld._m00_m10_m20),length(unity_ObjectToWorld._m01_m11_m21),length(unity_ObjectToWorld._m02_m12_m22));
				float2 size = IN.vertex.xy * objectScale.xy;
				float3 pos = worldPos + right * size.x + up * size.y;
				OUT.vertex = TransformWorldToHClip(pos);
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}

			float4 PSMain(Varyings IN) : SV_Target
			{
				float2 uv = IN.uv.xy;
				return Flame(uv);
			}
			ENDHLSL
		}
	}
}