Shader "Torn Fabric"
{
	Subshader
	{
		Pass
		{
			Cull off
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

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 z = float2(2.0*ps.uv.xy-1.0);
				int i=0;
				float r=0;
				while(i++<9) z=float2(z.x*z.x-z.y*z.y+.1,z.x*z.y*4.+.4);
				r=dot(z,z)<3.?z.y:0.;
				return float4(r,0,0,1);			
			}
			ENDCG
		}
	}
}