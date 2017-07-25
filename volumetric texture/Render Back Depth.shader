Shader "Hidden/Ray Marching/Render Back Depth" 
{
	Subshader 
	{ 	
		Tags {"RenderType"="Volume"}
		Cull Front
		Pass 
		{
		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 local_vertex : TEXCOORD0;
			};
		
			custom_type vertex_shader(float4 vertex:POSITION) 
			{
				custom_type vs;
				vs.screen_vertex = UnityObjectToClipPos(vertex);
				vs.local_vertex = vertex.xyz + 0.5;
				return vs;
			}

			float4 pixel_shader(custom_type ps) : COLOR 
			{ 
				return float4(ps.local_vertex, 1.0);
			}
		
			ENDCG


		}
	}
}
