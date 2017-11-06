Shader "Abyss"
{
	Properties
	{
		_intensity ("Intensity",Float) = 1.0
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			float _intensity;
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float t = pow(ps.uv.y,_intensity);
				return float4(t,t,t,1.0);	
			}
			ENDCG
		}
	}
}