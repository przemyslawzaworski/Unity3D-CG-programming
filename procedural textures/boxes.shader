Shader "Boxes"
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

			float box (float2 uv,float2 o)
			{
				return abs(1.2-acos(abs(uv.x+o.x)+abs(uv.y+o.y)));
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = 2.0*ps.uv.xy-1.0;
				float3 o = float3(0.0,1.0,-1.0);
				float c = (max(max(max(max(box(uv,o.xx),box(uv,o.yy)),box(uv,o.zz)),box(uv,o.zy)),box(uv,o.yz)));
				return float4(c,c,c,1.0);	
			}
			ENDCG
		}
	}
}