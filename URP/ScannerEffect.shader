// Unlit + transparency + URP + VR support
Shader "Scanner Effect URP"
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
	
			Varyings VSMain(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}
			
			float Modulo(float x, float y)
			{
				return x - y * floor(x/y);
			}			
			
			float4 ScanningEffect(float2 uv)
			{
				uv = float2(2.0*uv-1.0);
				float3 rayOrigin = float3(0.0, 0.0, 0.0);
				float3 rayDir = normalize(float3(uv, 2.0));
				float3 color = float3(0.0, 0.0, 0.0);
				float gridScale = 0.05;
				float lineWidth = 0.125;
				float fadeStrength = 2.0;
				float t1 = (-0.2 - rayOrigin.y) / rayDir.y;
				if (t1 > 0.0) 
				{
					float3 hit = rayOrigin + rayDir * t1;
					float dist = length(hit - rayOrigin);
					float2 gridUV = hit.xz / gridScale;
					float2 line1 = abs(frac(gridUV - 0.5) - 0.5);
					float lineMask = 1.0 - smoothstep(0.0, lineWidth, min(line1.x, line1.y));
					float fade = exp(-dist * fadeStrength);
					float3 baseColor = float3(lineMask,lineMask,lineMask) * fade;
					float scanZ = Modulo(_Time.g * 1.0, 2.0);
					float diff = abs(hit.z - scanZ);
					float pulse = exp(-diff * 10.0);
					float3 pulseColor = float3(1.0, 1.0, 0.3);
					color = baseColor + pulseColor * pulse;
				}
				float t2 = (0.2 - rayOrigin.y) / rayDir.y;
				if (t2 > 0.0 && (t2 < t1 || t1 < 0.0)) 
				{
					float3 hit = rayOrigin + rayDir * t2;
					float dist = length(hit - rayOrigin);
					float2 gridUV = hit.xz / gridScale;
					float2 line1 = abs(frac(gridUV - 0.5) - 0.5);
					float lineMask = 1.0 - smoothstep(0.0, lineWidth, min(line1.x, line1.y));
					float fade = exp(-dist * fadeStrength);
					float3 baseColor = float3(lineMask,lineMask,lineMask) * fade;
					float scanZ = Modulo(_Time.g * 1.0, 2.0);
					float diff = abs(hit.z - scanZ);
					float pulse = exp(-diff * 10.0);
					float3 pulseColor = float3(1.0, 1.0, 0.3);
					color = baseColor + pulseColor * pulse;
				}

				float t3 = (-0.45 - rayOrigin.x) / rayDir.x;
				if (t3 > 0.0 && (t3 < t1 || t1 < 0.0) && (t3 < t2 || t2 < 0.0)) 
				{
					float3 hit = rayOrigin + rayDir * t3;
					float dist = length(hit - rayOrigin);
					float2 gridUV = hit.zy / gridScale;
					float2 line1 = abs(frac(gridUV - 0.5) - 0.5);
					float lineMask = 1.0 - smoothstep(0.0, lineWidth, min(line1.x, line1.y));
					float fade = exp(-dist * fadeStrength);
					float3 baseColor = float3(lineMask,lineMask,lineMask) * fade;
					float scanZ = Modulo(_Time.g * 1.0, 2.0);
					float diff = abs(hit.z - scanZ);
					float pulse = exp(-diff * 10.0);
					float3 pulseColor = float3(1.0, 1.0, 0.3);
					color = baseColor + pulseColor * pulse;
				}
				float t4 = (0.45 - rayOrigin.x) / rayDir.x;
				if (t4 > 0.0 && (t4 < t1 || t1 < 0.0) && (t4 < t2 || t2 < 0.0) && (t4 < t3 || t3 < 0.0)) 
				{
					float3 hit = rayOrigin + rayDir * t4;
					float dist = length(hit - rayOrigin);
					float2 gridUV = hit.zy / gridScale;
					float2 line1 = abs(frac(gridUV - 0.5) - 0.5);
					float lineMask = 1.0 - smoothstep(0.0, lineWidth, min(line1.x, line1.y));
					float fade = exp(-dist * fadeStrength);
					float3 baseColor = float3(lineMask,lineMask,lineMask) * fade;
					float scanZ = Modulo(_Time.g * 1.0, 2.0);
					float diff = abs(hit.z - scanZ);
					float pulse = exp(-diff * 10.0);
					float3 pulseColor = float3(1.0, 1.0, 0.3);
					color = baseColor + pulseColor * pulse;
				}
				return float4(color, 1.0);			
			}

			float4 PSMain(Varyings IN) : SV_Target
			{
				float2 uv = IN.uv.xy;
				return ScanningEffect(uv);
			}
			ENDHLSL
		}
	}
}