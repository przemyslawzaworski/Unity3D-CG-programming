//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;).
//Set camera position (0,0,-10). Apply fly script to the camera. Play.
Shader "Voxel torus"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
				
			static const float voxel_size = 0.1;
			
			float torus (float3 p, float2 t) //torus signed distance field function
			{
				float2 q = float2(length(p.xz)-t.x,p.y);
				return length(q)-t.y;
			}

			float map (float3 p) //scene geometry
			{
				return torus(p-float3(4,4,4),float2(2.0,0.6));
			}

			float4 lighting (float3 p, float3 normal) //surface color
			{
				float3 voxel = fmod(p, voxel_size) / voxel_size;
				float3 a = max(abs(normal), smoothstep(0.0, 0.1, voxel));
				float3 b = max(abs(normal), smoothstep(0.0, 0.1, 1.0 - voxel));
				float Line = a.x * a.y * a.z *b.x * b.y * b.z;
				float4 AmbientLight = float4 (0.2,0.2,0.2,1.0);
				float3 LightDirection = normalize(float3(1,1,-20));
				float3 NormalDirection = normal;
				float4 LightColor = float4(0.7,0.7,0.7,1.0) ;   
				float4 Lambert =  max(dot(LightDirection,NormalDirection),0.0)*LightColor+AmbientLight;      
				return lerp(float4(0,0,1,1.0), Lambert, Line);
			}
			
			float4 raymarch (float3 ro, float3 rd) //renderer
			{
				float3 voxel = floor(ro / voxel_size);
				float3 next = ((voxel + max(sign(rd), 0.0)) * voxel_size - ro) / rd;
				float3 step = sign(rd);
				float3 delta = voxel_size / abs(rd);
				float3 normal;
				float t = 0.0;
				for(int i = 0; i < 256; i++)
				{
					float d = map(voxel * voxel_size);
					if (d < 0.0001) 
					{				
						ro += rd*t*(1.0-abs(normal));
						return lighting(ro,normal);
					}
					if(next.x < next.y && next.x < next.z)
					{
						voxel.x += step.x;
						t = next.x;
						next.x += delta.x;
						normal = float3(-step.x, 0.0, 0.0);
					}
					else if(next.y < next.x && next.y < next.z) 
					{
						voxel.y += step.y;
						t = next.y;
						next.y += delta.y;
						normal = float3(0.0, -step.y, 0.0);
					}
					else if(next.z < next.x && next.z < next.y) 
					{
						voxel.z += step.z;
						t = next.z;
						next.z += delta.z;
						normal = float3(0.0, 0.0, -step.z);
					}
				}
				return float4(0,0,0,1);
			}

			custom_type vertex_shader (float4 vertex:POSITION) //vertex shader 
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.world_vertex = mul(_Object2World,vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ):SV_TARGET //fragment shader
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex-_WorldSpaceCameraPos.xyz);
				return raymarch(worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}