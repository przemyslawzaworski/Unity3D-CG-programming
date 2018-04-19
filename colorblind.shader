Shader "ColorBlind"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		[KeywordEnum(Normal,Protanopia,Protanomaly,Deuteranopia,Deuteranomaly,Tritanopia,Tritanomaly,Achromatopsia,Achromatomaly)] modes("Filters", Float) = 0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			float modes;

			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			static const float3x3 ColorMatrix[9] = 
			{
				float3x3(1.000, 0.000, 0.000,  0.000, 1.000, 0.000,  0.000, 0.000, 1.000), 
				float3x3(0.567, 0.433, 0.000,  0.558, 0.442, 0.000,  0.000, 0.242, 0.758), 
				float3x3(0.817, 0.183, 0.000,  0.333, 0.667, 0.000,  0.000, 0.125, 0.875), 
				float3x3(0.625, 0.375, 0.000,  0.700, 0.300, 0.000,  0.000, 0.300, 0.700), 
				float3x3(0.800, 0.200, 0.000,  0.258, 0.742, 0.000,  0.000, 0.142, 0.858), 
				float3x3(0.950, 0.050, 0.000,  0.000, 0.433, 0.567,  0.000, 0.475, 0.525), 
				float3x3(0.967, 0.033, 0.000,  0.000, 0.733, 0.267,  0.000, 0.183, 0.817), 
				float3x3(0.299, 0.587, 0.114,  0.299, 0.587, 0.114,  0.299, 0.587, 0.114), 
				float3x3(0.618, 0.320, 0.062,  0.163, 0.775, 0.062,  0.163, 0.320, 0.516)
			};
			
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float3 c = tex2D(_MainTex,ps.uv.xy);
				c = mul(ColorMatrix[int(modes)],c);
				return float4(c.rgb,1.0);
			}

			ENDCG
		}
	}
}