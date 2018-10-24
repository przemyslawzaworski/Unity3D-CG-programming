Shader "Hidden/Post FX/Bloom"
{ 
    Properties
    {
        _MainTex ("", 2D) = "" {}
        _BaseTex ("", 2D) = "" {}
        _AutoExposure ("", 2D) = "" {}
    }

    CGINCLUDE
    #pragma target 3.0	
	float4 _MainTex_ST;
	float4 _MainTex_TexelSize;
	sampler2D _MainTex;	
	ENDCG

	SubShader
	{
		ZTest Always Cull Off ZWrite Off
		
		Pass
		{
			CGPROGRAM
			#pragma multi_compile __ ANTI_FLICKER
			#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader

			sampler2D _AutoExposure;
			float3 _Curve;
			float _Threshold;	
			float _PrefilterOffs;
			
			void SetVertexShader(inout float4 vertex : POSITION, inout float2 texcoord : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}	

			half Brightness(half3 c)
			{
				return max(c.x, max(c.y, c.z));
			}

			half3 Median(half3 a, half3 b, half3 c)
			{
				return a + b + c - min(min(a, b), c) - max(max(a, b), c);
			}

			half4 FetchAutoExposed(sampler2D tex, float2 uv)
			{
				float autoExposure = 1.0;
				autoExposure = tex2D(_AutoExposure, uv).r;
				return tex2D(tex, uv) * autoExposure;
			}
			
			half4 SetPixelShader(in float4 vertex : POSITION, in float2 texcoord : TEXCOORD0) : SV_Target
			{
				float2 uv = texcoord + _MainTex_TexelSize.xy * _PrefilterOffs;
				#if ANTI_FLICKER
					float3 d = _MainTex_TexelSize.xyx * float3(1.0, 1.0, 0.0);
					half4 s0 = min(FetchAutoExposed(_MainTex, uv),65504.0);
					half3 s1 = min(FetchAutoExposed(_MainTex, uv - d.xz).rgb,65504.0);
					half3 s2 = min(FetchAutoExposed(_MainTex, uv + d.xz).rgb,65504.0);
					half3 s3 = min(FetchAutoExposed(_MainTex, uv - d.zy).rgb,65504.0);
					half3 s4 = min(FetchAutoExposed(_MainTex, uv + d.zy).rgb,65504.0);
					half3 m = Median(Median(s0.rgb, s1, s2), s3, s4);
				#else
					half4 s0 = min(FetchAutoExposed(_MainTex, uv),65504.0);
					half3 m = s0.rgb;
				#endif
				#if UNITY_COLORSPACE_GAMMA
					m = m * (m * (m * 0.305306011h + 0.682171111h) + 0.012522878h);
				#endif
				half br = Brightness(m);
				half rq = clamp(br - _Curve.x, 0.0, _Curve.y);
				rq = _Curve.z * rq * rq;
				m *= max(rq, br - _Threshold) / max(br, 1e-5);
				return half4(m,0);
			}			
			
			ENDCG
		}
		
		Pass
		{
			CGPROGRAM
			#pragma multi_compile __ ANTI_FLICKER
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader
			
			half Brightness(half3 c)
			{
				return max(c.x, max(c.y, c.z));
			}
			
			half3 DownsampleFilter(sampler2D tex, float2 uv, float2 texelSize)
			{
				float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
				half3 s;
				s = tex2D(tex, uv + d.xy).rgb;
				s += tex2D(tex, uv + d.zy).rgb;
				s += tex2D(tex, uv + d.xw).rgb;
				s += tex2D(tex, uv + d.zw).rgb;
				return s * (1.0 / 4.0);
			}

			half3 DownsampleAntiFlickerFilter(sampler2D tex, float2 uv, float2 texelSize)
			{
				float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
				half3 s1 = tex2D(tex, uv + d.xy).rgb;
				half3 s2 = tex2D(tex, uv + d.zy).rgb;
				half3 s3 = tex2D(tex, uv + d.xw).rgb;
				half3 s4 = tex2D(tex, uv + d.zw).rgb; 
				half s1w = 1.0 / (Brightness(s1) + 1.0);
				half s2w = 1.0 / (Brightness(s2) + 1.0);
				half s3w = 1.0 / (Brightness(s3) + 1.0);
				half s4w = 1.0 / (Brightness(s4) + 1.0);
				half one_div_wsum = 1.0 / (s1w + s2w + s3w + s4w);
				return (s1 * s1w + s2 * s2w + s3 * s3w + s4 * s4w) * one_div_wsum;
			}
	
			void SetVertexShader(inout float4 vertex : POSITION, inout float2 texcoord : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			half4 SetPixelShader(in float4 vertex : POSITION, in float2 texcoord : TEXCOORD0) : SV_Target
			{
				#if ANTI_FLICKER
					return half4(DownsampleAntiFlickerFilter(_MainTex, texcoord, _MainTex_TexelSize.xy),0);
				#else
					return half4(DownsampleFilter(_MainTex, texcoord, _MainTex_TexelSize.xy),0);
				#endif
			}
			
			ENDCG
		}
		
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader
			
			void SetVertexShader(inout float4 vertex : POSITION, inout float2 texcoord : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			half3 DownsampleFilter(sampler2D tex, float2 uv, float2 texelSize)
			{
				float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
				half3 s;
				s = tex2D(tex, uv + d.xy).rgb;
				s += tex2D(tex, uv + d.zy).rgb;
				s += tex2D(tex, uv + d.xw).rgb;
				s += tex2D(tex, uv + d.zw).rgb;
				return s * (1.0 / 4.0);
			}
			
			half4 SetPixelShader(in float4 vertex : POSITION, in float2 texcoord : TEXCOORD0) : SV_Target
			{
				return half4(DownsampleFilter(_MainTex, texcoord, _MainTex_TexelSize.xy),0);
			}
			
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader

			float _SampleScale;	
			sampler2D _BaseTex;
			float2 _BaseTex_TexelSize;
	
			struct SHADERDATA
			{
				float4 pos : SV_POSITION;
				float2 uvMain : TEXCOORD0;
				float2 uvBase : TEXCOORD1;
			};

			half3 UpsampleFilter(sampler2D tex, float2 uv, float2 texelSize, float sampleScale)
			{
				float4 d = texelSize.xyxy * float4(1.0, 1.0, -1.0, 0.0) * sampleScale;
				half3 s;
				s =  tex2D(tex, uv - d.xy).rgb;
				s += tex2D(tex, uv - d.wy).rgb * 2.0;
				s += tex2D(tex, uv - d.zy).rgb;
				s += tex2D(tex, uv + d.zw).rgb * 2.0;
				s += tex2D(tex, uv).rgb        * 4.0;
				s += tex2D(tex, uv + d.xw).rgb * 2.0;
				s += tex2D(tex, uv + d.zy).rgb;
				s += tex2D(tex, uv + d.wy).rgb * 2.0;
				s += tex2D(tex, uv + d.xy).rgb;
				return s * (1.0 / 16.0);
			}
			
			SHADERDATA SetVertexShader(float4 vertex : POSITION, float2 texcoord : TEXCOORD0)
			{
				SHADERDATA o;
				o.pos = UnityObjectToClipPos(vertex);
				o.uvMain = texcoord.xy;
				o.uvBase = o.uvMain;
				#if UNITY_UV_STARTS_AT_TOP
					if (_BaseTex_TexelSize.y < 0.0) o.uvBase.y = 1.0 - o.uvBase.y;
				#endif
				return o;
			}

			half4 SetPixelShader(SHADERDATA i) : SV_Target
			{
				half3 base = tex2D(_BaseTex, i.uvBase).rgb;
				half3 blur = UpsampleFilter(_MainTex, i.uvMain, _MainTex_TexelSize.xy, _SampleScale);
				return half4(base + blur,0);
			}			
			ENDCG
		}
	}
}