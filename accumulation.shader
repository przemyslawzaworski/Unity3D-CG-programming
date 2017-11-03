Shader "Accumulation"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
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
				float4 screen_vertex : SV_POSITION;
				float2 uv: TEXCOORD0;
			};
		
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP, vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float2 uv = ps.uv.xy;
				float4 c = tex2D(_MainTex,uv);
				if (uv.x>0.5) c.x+=0.005;
				return c;
			}

			ENDCG

		}
	}
}