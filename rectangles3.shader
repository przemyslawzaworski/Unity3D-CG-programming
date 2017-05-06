//based on tutorial from http://theorangeduck.com/page/avoiding-shader-conditionals
Shader "Rectangles3"
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
				float x = ps.uv.x;
				float y = ps.uv.y;
				float2 center1 = float2(0.2,0.8);
				float2 center2 = float2(0.5,0.8);
				float2 center3 = float2(0.8,0.8);
			 	return float4(1.0,0.0,0.0,1.0)*max(sign(0.1-abs(center1.x-x)),0.0)*max(sign(0.1-abs(center1.y-y)),0.0)
			 	+float4(1.0,0.0,0.0,1.0)*max(sign(0.1-abs(center2.x-x)),0.0)*max(sign(0.1-abs(center2.y-y)),0.0)
    			+float4(1.0,0.0,0.0,1.0)*max(sign(0.1-abs(center3.x-x)),0.0)*max(sign(0.1-abs(center3.y-y)),0.0);
			}

			ENDCG
		}
	}
}