Shader "Triangle"
{
	SubShader
	{	
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
				
			struct structure 
			{ 
				float4 vertex : SV_POSITION; 
				float3 color : COLOR; 
			};

			structure vertex_shader(uint id : SV_VertexID) 
			{
				structure vs; 			
				float4 vertices[3];
				vertices[0] = float4( 0.0,-0.5,0.001,1.0);
				vertices[1] = float4( 0.5, 0.5,0.001,1.0);
				vertices[2] = float4(-0.5, 0.5,0.001,1.0);			
				float3 colors[3];
				colors[0] = float3(1,0,0); 
				colors[1] = float3(0,1,0); 
				colors[2] = float3(0,0,1); 			
				if (id>2)
				{
					vs.vertex = float4(0.0, -0.5, 0.001, 1.0);
					vs.color = float3(1.0, 0.0, 0.0);
				}
				else
				{
					vs.vertex = vertices[id];
					vs.color = colors[id];						
				}
				return vs;
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target) 
			{
				fragColor = float4(ps.color,1);
			}
			ENDCG
		}
	}
}