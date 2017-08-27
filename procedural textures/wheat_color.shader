Shader "Wheat Color"
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
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 u = ps.uv.xy;
				float2 p = float2(2.0*u-1.0);
				float3 c = float3(0.96,0.87,0.70);      
				c = c*(1.0-0.15*length(p));
				return float4 (pow(c,float3(0.555,0.555,0.555)),1.0);			
			}
			ENDCG
		}
	}
}