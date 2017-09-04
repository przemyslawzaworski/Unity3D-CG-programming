Shader "Ribbons"
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 u = float2(2.0*ps.uv.xy-1.0);
				u=abs(fmod(u,fmod(atan(u.y),fmod(atan(u.x),atan(u.y)))));
				return float4 (u,u.x*u.y,1)*4.0;		
			}
			ENDCG
		}
	}
}