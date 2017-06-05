//For every input vertex, shader creates new primitive (blue quad from two triangles).
Shader "Unlit_Geometry_Shader" 
{
	SubShader 
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vertex_shader
			#pragma geometry geometry_shader
			#pragma fragment pixel_shader

			struct custom_type
			{
				float4 pos : SV_POSITION;
			};

			custom_type vertex_shader(float4 vertex:POSITION)
			{
				custom_type vs ;
				vs.pos = mul(_Object2World, vertex);
				return vs;
			}

			[maxvertexcount(6)]
			void geometry_shader(point custom_type input[1], inout TriangleStream<custom_type> stream)
			{
				custom_type gs;	
				float3 delta = float3 (0.25, 0.00, 0.00);
				float4 vertices[6];
				vertices[0] = float4(input[0].pos.xyz + delta.yyy, 1.0f);
				vertices[1] = float4(input[0].pos.xyz + delta.yyx, 1.0f);
				vertices[2] = float4(input[0].pos.xyz + delta.xyy, 1.0f);
				vertices[3] = float4(input[0].pos.xyz + delta.xyx, 1.0f);
				vertices[4] = float4(input[0].pos.xyz + delta.xyy, 1.0f);
				vertices[5] = float4(input[0].pos.xyz + delta.yyx, 1.0f);
				float4x4 m = mul(UNITY_MATRIX_MVP, _World2Object);			
				for (int i=0;i<6;i++)
				{
					gs.pos = mul(m, vertices[i]);
					stream.Append(gs);
				}
			}

			float4 pixel_shader(custom_type ps) : SV_TARGET
			{
				return float4(0.0,0.0,1.0,1.0);
			}

			ENDCG
		}
	} 
}
