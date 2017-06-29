Shader "Clockwise triangles"
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

			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 uv = ps.uv.xy;
				float4 a =lerp(float4(1.0,1.0,1.0,1.0),float4(0.0,0.0,0.0,1.0),(step(step(uv.y,1.0-uv.x),step(uv.x,uv.y))));
				float4 b =lerp(float4(1.0,1.0,1.0,1.0),float4(0.0,0.0,0.0,1.0),(step(step(uv.y,1.0-uv.x),step(uv.y,uv.x))));
				float4 c =lerp(float4(1.0,1.0,1.0,1.0),float4(0.0,0.0,0.0,1.0),(step(step(1.0-uv.y,uv.x),step(uv.y,uv.x))));
				float4 d =lerp(float4(1.0,1.0,1.0,1.0),float4(0.0,0.0,0.0,1.0),(step(step(1.0-uv.y,uv.x),step(uv.x,uv.y))));    
				float t = fmod(floor(_Time.g),4.0);    
				return float4 (a *(1.0-abs(sign(t-0.0)))+ b*(1.0-abs(sign(t-1.0)))+c*(1.0-abs(sign(t-2.0)))+d*(1.0-abs(sign(t-3.0))));
			}
			ENDCG
		}
	}
}