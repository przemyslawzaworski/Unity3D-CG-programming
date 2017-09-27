// Reference: http://glslsandbox.com/e#29611.0
Shader "Fractal Image"
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
				float4 c = float4(ps.uv.xy,1.5,0);
				for (int i = 0; i < 234; i++)
				{
					c.xzy = float3(1.3,1.0,0.78)*abs(c.xyz/dot(c,c)-float3(1,1,0));	
				}
				return c;
			}
			
			ENDCG
		}
	}
}