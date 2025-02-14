// Unlit + transparency + URP + VR support
Shader "Hexagons URP"
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

			/* Function creates a hexagonal grid pattern by first calculating centers for two staggered grids 
			and then choosing the closer one based on distance. It computes a signed distance from the UV coordinate
			to the nearest hexagon border and uses a smoothstep to generate an anti-aliased grid line based 
			on a specified thickness. Finally, it returns a float4 containing the SDF value, the grid mask, 
			and the coordinates of the nearest hexagon center. */
			float4 HexagonalGrid(float2 uv, float thickness)
			{
				float2 scale = float2(1.0, 1.7320508);
				float4 center = floor(float4(uv, uv - float2(0.5, 1.0)) / scale.xyxy) + 0.5;
				float4 offset = float4(uv - center.xy * scale, uv - (center.zw + 0.5) * scale);
				bool close = dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw);
				float4 near = close ? float4(abs(offset.xy), center.xy) : float4(abs(offset.zw), center.zw + 0.5);
				float sdf = max(dot(near.xy, scale * 0.5), near.x);
				float grid = smoothstep(0.0, 0.001, sdf - 0.5 + thickness);
				return float4(sdf, grid, near.zw);
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
				return OUT;
			}

			float4 PSMain(Varyings IN) : SV_Target
			{
				float2 uv = IN.uv.xy;
				float4 hex = HexagonalGrid(50.0 * uv, 0.05);
				float3 color = hex.yyy;
				float alpha = hex.y;
				return float4(color.rgb, alpha);
			}
			ENDHLSL
		}
	}
}