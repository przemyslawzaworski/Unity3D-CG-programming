Shader "Negation"
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

			sampler2D _MainTex : register(s0);

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				return float4 (1,1,1,1)-tex2D(_MainTex,ps.uv);
			}

			ENDCG
		}
	}
}