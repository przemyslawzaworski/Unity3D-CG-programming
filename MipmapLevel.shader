Shader "MipmapLevel"
{
	Properties
	{
		_MainTex ("Base Map", 2D) = "black" {}
		[KeywordEnum(Intrinsic, Estimated)] _Mode("Mode", int) = 0
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			Texture2D _MainTex;
			SamplerState sampler_linear_repeat; // Isotropic LOD works only for point and linear filter
			float4 _MainTex_TexelSize;
			int _Mode;

			static const float3 Palette[16] =
			{
				float3(1.0, 0.0, 0.0),  // Red
				float3(0.0, 0.5, 0.0),  // Green
				float3(0.0, 0.0, 1.0),  // Blue
				float3(1.0, 1.0, 0.0),  // Yellow
				float3(1.0, 1.0, 1.0),  // White
				float3(0.0, 1.0, 1.0),  // Cyan
				float3(0.5, 0.5, 0.5),  // Gray
				float3(1.0, 0.5, 0.0),  // Orange
				float3(0.5, 1.0, 0.0),  // Lime
				float3(0.0, 0.5, 1.0),  // Sky Blue
				float3(1.0, 0.0, 0.5),  // Pink
				float3(0.5, 0.0, 1.0),  // Purple
				float3(0.0, 1.0, 0.5),  // Sea Green
				float3(0.5, 1.0, 1.0),  // Light Blue
				float3(1.0, 0.5, 1.0),  // Orchid
				float3(0.5, 0.0, 0.0)   // Maroon
			};

			// https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm#7.18.11%20LOD%20Calculations
			float MipmapLevelIsotropic(float2 uv, float2 resolution)
			{
				float2 dx = ddx(uv) * resolution;
				float2 dy = ddy(uv) * resolution;
				return log2(max(length(dx), length(dy)));
			}

			float4 VSMain (float4 vertex : POSITION, inout float2 uv : TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float2 uv : TEXCOORD0) : SV_TARGET
			{
				float2 resolution = _MainTex_TexelSize.zw;
				int intrinsic = (int) _MainTex.CalculateLevelOfDetailUnclamped(sampler_linear_repeat, uv);
				int estimated = (int) MipmapLevelIsotropic(uv, resolution);
				int index = (_Mode == 0) ? intrinsic : estimated;
				return (index < 0) ? float4(0,0,0,1) : float4(Palette[(uint)index], 1.0);
			}
			ENDCG
		}
	}
}