Shader "Hidden/Post FX/Uber Shader"
{ 
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AutoExposure ("", 2D) = "" {}
		_BloomTex ("", 2D) = "" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader	
			#pragma target 3.0
			#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
			#pragma multi_compile __ BLOOM BLOOM_LENS_DIRT

			sampler2D _AutoExposure; 
			sampler2D _BloomTex; 
			float4 _BloomTex_TexelSize;
			half2 _Bloom_Settings; // x: sampleScale, y: bloom.intensity 				
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			sampler2D _MainTex;
			
			half3 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
			{
				float4 d = texelSize.xyxy * float4(1.0, 1.0, -1.0, 0.0) * sampleScale;
				half3 s;
				s =  tex2D(tex, uv - d.xy).rgb;
				s += tex2D(tex, uv - d.wy).rgb * 2.0;
				s += tex2D(tex, uv - d.zy).rgb;
				s += tex2D(tex, uv + d.zw).rgb * 2.0;
				s += tex2D(tex, uv).rgb * 4.0;
				s += tex2D(tex, uv + d.xw).rgb * 2.0;
				s += tex2D(tex, uv + d.zy).rgb;
				s += tex2D(tex, uv + d.wy).rgb * 2.0;
				s += tex2D(tex, uv + d.xy).rgb;
				return s * (1.0 / 16.0);
			}
			
			void SetVertexShader(inout float4 vertex : POSITION, inout float2 texcoord : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			half4 SetPixelShader(in float4 vertex : POSITION, in float2 texcoord : TEXCOORD0) : SV_Target
			{
				float2 uv = texcoord;
				half autoExposure = tex2D(_AutoExposure, uv).r;
				half3 color = (0.0).xxx;
				color = tex2D(_MainTex, texcoord).rgb;
				color *= autoExposure;
				#if UNITY_COLORSPACE_GAMMA  //GammaToLinearSpace
				{
					color = color * (color * (color * 0.305306011h + 0.682171111h) + 0.012522878h);
				}
				#endif
				half3 bloom = UpsampleFilter(_BloomTex, texcoord, _BloomTex_TexelSize.xy, _Bloom_Settings.x) * _Bloom_Settings.y;
				color += bloom;
				color = saturate(color);
				#if UNITY_COLORSPACE_GAMMA //LinearToGammaSpace
				{
					color = max(color, half3(0.h, 0.h, 0.h));
					color = max(1.055h * pow(color, 0.416666667h) - 0.055h, 0.h);
				}
				#endif 
				return half4(color, 1.0);
			}

			ENDCG
		}
	}
}