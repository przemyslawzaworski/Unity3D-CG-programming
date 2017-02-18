Shader "Noise Grayscale"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			struct custom_type
			{
				float4 clip_space_vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (float4 object_space_vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.clip_space_vertex = mul (UNITY_MATRIX_MVP,object_space_vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float noise = frac(sin(dot(ps.uv.xy,float2(12.9898,78.233))) * 43758.5453);
				return float4 (noise,noise,noise,1.0);
			}

			ENDCG
		}
	}
}