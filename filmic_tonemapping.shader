//reference: "Filmic Tonemapping for Real-time Rendering" Siggraph 2010 Course by Haarm-Pieter Duiker.
Shader "Filmic tonemapping"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float4 filmic_tonemapping(float3 x)
			{
				x = max(float3(0,0,0), x - float3(0.004,0.004,0.004));
				x = (x * (6.2 * x + .5)) / (x * (6.2 * x + 1.7) + 0.06);
				return float4(x,1.0);
			}

			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 u = ps.uv.xy;
				float4 color = tex2D(_MainTex,u);
				return filmic_tonemapping(color);
			}
			ENDCG
		}
	}
}