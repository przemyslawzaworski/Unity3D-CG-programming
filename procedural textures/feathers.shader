Shader "Feathers"
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
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 o = abs(7.5*float2(2.0*ps.uv.xy-1.0));
				float shape = 10.0-abs(lerp(o.x,o.y,10.0*cos(o.x*o.y)));    
				return float4(shape,0.0,0.0,1.0);			
			}
			ENDCG
		}
	}
}