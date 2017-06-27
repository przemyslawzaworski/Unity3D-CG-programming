//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
Shader "Raymarching Materials Integration"
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
			
			float4 _LightColor0;	
			
			float4 hexagon (float3 p, float3 c, float2 h)
			{
				float3 q = abs(p+c);
				float3 m = float3 (1.0,0.0,0.0);
				return float4 (m,max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x));
			}
			
			float4 sphere (float3 p,float3 c,float r)
			{
				float3 m = float3 (0.0,0.0,1.0);
				return float4 (m,length (p-c)-r);
			}

			float4 ring (float3 p, float3 c, float2 t)
			{
				float3 m = float3(1.0,0.64,0.0);
				float2 q = float2(sqrt((p.x-c.x)*(p.x-c.x) + (p.z-c.z)*(p.z-c.z) )-t.x,p.y-c.y);
				q=q*q; q=q*q; q=q*q;
				return float4(m,pow( q.x + q.y, 0.125 )-t.y);
			}
					
			float4 map (float3 p)
			{
				float4 solid = lerp (hexagon(p,float3(3,0,0),float2(1,1)), sphere(p,float3(3,0,0),1.0), step(sphere(p,float3(3,0,0),1.0).w,hexagon(p,float3(3,0,0),float2(1,1)).w ));
				return lerp (ring(p,float3(0,3,0),float2(1,0.25)), solid, step(solid.w,ring(p,float3(0,3,0),float2(1,0.25)).w ));
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x).w-map(p-x).w, map(p+y).w-map(p-y).w, map(p+z).w-map(p-z).w)); 
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(-_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.xyz;
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight);
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = map(ro).w;
					float3 material = map(ro).xyz;
					if (ray < 0.001) return float4 (lighting(ro)*material,1.0); else ro+=ray*rd; 
				}
				clip(-1);
				return float4 (0.0,0.0,0.0,1.0);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP, vertex);
				vs.world_vertex = mul (_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}