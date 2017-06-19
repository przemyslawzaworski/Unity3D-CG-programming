Shader "Bitwise test"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float2 uv: TEXCOORD0;
			};
		
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP, vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				uint n = 1;
				return lerp (float4(0.0,0.0,1.0,1.0),float4(0.0,1.0,1.0,1.0),step(ps.uv.x,(0.1*(n<<=3))));  
				// left bit shift equivalent to 0.1 * n * pow(2,3)
			}

			ENDCG

		}
	}
}