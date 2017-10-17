/*Set Main Camera to following position (0,50,0).
In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). 
Add fly script to Main Camera. Play. 
Or just bind material with shader to any gameobject to create volumetric effect :) */

Shader "City"
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

			float hash (float2 n) 
			{ 
				return frac(sin(dot(n, float2(12.9898, 4.1414)))*43758.5453);
			}

			float map (float3 p)
			{
				float2 u = floor(p.xz*0.005*64.0)/64.0;
				float h = hash(u);
				h = p.y - lerp(0.0,8.0,pow(h,2.0));
				return max( min( h, 0.1), p.y-8.0 );
			}
			
			float4 color (float3 ro)
			{
				float m = ro.y/8.0;
				float4 buildings = float4 (m,m,m,1.0);
				float4 grass = float4(0,0.05,0,1);
				return lerp(buildings,grass,step(ro.y,0.1));
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<512; i++)
				{
					float t = map(ro);
					if (ro.x>300.0 || ro.x<-300.0 || ro.z>300.0 || ro.z<-300.0) break;
					if ( t<0.001 ) return color(ro);
					ro+=t*rd;
				}
				return float4(0.0,0.0,1.0,0.0);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.world_vertex = mul (_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex-_WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}