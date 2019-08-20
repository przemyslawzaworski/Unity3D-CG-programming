Shader "AmbientOcclusion"
{
	Properties
	{
		[HideInInspector] _MainTex ("Texture", 2D) = "white" {}
		[MaterialToggle] Debug("Debug", Float) = 0
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _CameraDepthNormalsTexture;
			float Radius, Bias, Intensity, SampleCount, Debug;
			float3 Kernel[256];

			float4 VSMain (float4 vertex:POSITION, inout float2 uv:TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}
			
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_Target
			{
				float3 normal = DecodeViewNormalStereo( tex2D(_CameraDepthNormalsTexture, uv) );
				float depth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, uv).zw);
				float scale = Radius / (depth * _ProjectionParams.z);               
				float ao = 0.0;
				for(int i = 0; i < SampleCount; i++)
				{
					float3 sample = Kernel[i];
					float3 p = float3(i, uv);
					float hash = frac(sin(p.x * dot(p ,float3(12.9898,78.233,45.5432))) * 43758.5453);
					float angle = radians(hash*360.0);
					float2x2 m = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
					sample = float3(mul(m, sample.xy), sample.z).zxy;
					if( dot(normal, sample) < 0.0f) sample *= -1.0f;    
					float2 offset = sample.xy * scale;     
					float delta = (depth - DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, uv + offset).zw)) * _ProjectionParams.z;
					float3 direction = float3(sample.xy * Radius, delta);                   
					float occ = max(0.0, dot(normal, normalize(direction)) - Bias) * (1.0 / (1.0+length(direction)) * Intensity);
					ao += 1.0 - occ;
				}
				ao /= SampleCount;
				ao *= ao;
				return clamp(ao, 0.0, 1.0);
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			float BlurOffset;

			float4 VSMain (float4 vertex:POSITION, inout float2 uv:TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}
		   
			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_Target
			{
				float4 base = tex2D(_MainTex, uv);
				float4 a = tex2D(_MainTex, uv + float2(0, BlurOffset * _MainTex_TexelSize.y));
				float4 b = tex2D(_MainTex, uv - float2(0, BlurOffset * _MainTex_TexelSize.y));
				float4 c = tex2D(_MainTex, uv + float2(BlurOffset * _MainTex_TexelSize.x, 0));
				float4 d = tex2D(_MainTex, uv - float2(BlurOffset * _MainTex_TexelSize.x, 0));
				return (base + a + b + c + d) / 5.0;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler2D _MainTex;
			sampler2D OcclusionMap;
			float Debug;

			float4 VSMain (float4 vertex:POSITION, inout float2 uv:TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_Target
			{
				float4 fragColor = tex2D(_MainTex, uv);
				float4 occlusion = tex2D(OcclusionMap, uv);
				if (Debug == 1)  return occlusion;
				return fragColor * occlusion.r;
			}
			ENDCG
		}
	}
}