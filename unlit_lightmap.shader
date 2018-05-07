Shader "Unlit LightMapping"
{
	Properties
	{
		_MainTex ("Base", 2D) = "white" {}
	}  
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma multi_compile LIGHTMAP_ON LIGHTMAP_OFF

			half4 unity_Lightmap_HDR;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			half3 DecodeLightmapRGBM (half4 data, half4 decodeInstructions)
			{
				#if defined(UNITY_COLORSPACE_GAMMA)
				#if defined(UNITY_FORCE_LINEAR_READ_FOR_RGBM)
					return (decodeInstructions.x * data.a) * sqrt(data.rgb);
				#else
					return (decodeInstructions.x * data.a) * data.rgb;
				#endif
				#else
					return (decodeInstructions.x * pow(data.a, decodeInstructions.y)) * data.rgb;
				#endif
			}

			half3 DecodeLightmapDoubleLDR( fixed4 color )
			{
				return 2.0 * color.rgb;
			}

			half3 DecodeLightmap( fixed4 color, half4 decodeInstructions)
			{
				#if defined(UNITY_NO_RGBM)
					return DecodeLightmapDoubleLDR( color );
				#else
					return DecodeLightmapRGBM( color, decodeInstructions );
				#endif
			}
	
			half3 DecodeLightmap( fixed4 color )
			{
				return DecodeLightmap( color, unity_Lightmap_HDR );
			}
			
			struct SHADERDATA
			{                     
				float4 vertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1; 
			};
			
			SHADERDATA vertex_shader(float4 vertex:POSITION, float2 uv0:TEXCOORD0, float2 uv1:TEXCOORD1)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv0 = uv0 * _MainTex_ST.xy + _MainTex_ST.zw;
				#ifdef LIGHTMAP_ON
					vs.uv1 = uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif  
				return vs;
			}
 
			float4 pixel_shader(SHADERDATA ps) : COLOR
			{
				float4 color = tex2D(_MainTex, ps.uv0) ;
				#ifdef LIGHTMAP_ON
					color.rgb *= DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, ps.uv1));
				#endif  
				return color;
			}
			ENDCG
		}
	}
}