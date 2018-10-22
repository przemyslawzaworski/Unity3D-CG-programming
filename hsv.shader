Shader "HSV"
{
	Properties
	{
		_MainTex ("Texture Map", 2D) = "white" {}
		_hue ("Hue",Range(0.0,1.0)) = 1.0
		_saturation ("Saturation",Range(0.0,1.0)) = 1.0
		_value ("Value (Brightness)",Range(0.0,1.0)) = 1.0		
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _hue, _saturation, _value;

			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}

			void SetVertexShader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			float4 SetPixelShader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				float4 color = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
				float3 source = RGBToHSV(color.rgb);
				source *= float3(_hue, _saturation, _value);
				color.rgb = HSVToRGB(source);
				return color;
			}
			
			ENDCG
		}
	}
}