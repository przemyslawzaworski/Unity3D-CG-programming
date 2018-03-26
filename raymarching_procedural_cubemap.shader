//see also: www.shadertoy.com

Shader "Raymarching Procedural Cubemap"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
			
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
				float2 q = float2(sqrt((p.x-c.x)*(p.x-c.x)+(p.z-c.z)*(p.z-c.z))-t.x,p.y-c.y);
				q=q*q; q=q*q; q=q*q;
				return float4(m,pow( q.x + q.y, 0.125 )-t.y);
			}
					
			float4 map (float3 p)
			{
				float4 a = hexagon(p,float3(3,0,0),float2(1,1));
				float4 b = sphere(p,float3(3,0,0),1.0);
				float4 c = ring(p,float3(0,3,0),float2(1,0.25));
				float4 solid = lerp (a,b,step(b.w,a.w));
				return lerp (c, solid, step(solid.w,c.w ));
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x).w-map(p-x).w,map(p+y).w-map(p-y).w,map(p+z).w-map(p-z).w)); 
			}
	
			float3 cubemap(float3 dir) 
			{
				float3 value = cos(dir*float3(1, 9, 2)+float3(2, 3, 1))*0.5+0.5;
				value = (value * float3(0.8, 0.3, 0.7)) + float3(0.2,0.2,0.2);
				value *= dir.y*0.5+0.5;
				value += exp(6.0*dir.y-2.0)*0.05;
				value = pow(value, float3(1.0/2.2,1.0/2.2,1.0/2.2));
				return value;
			}	
			
			float3 lighting (float3 p, float3 rd)
			{
				float3 ReflectionDirection=reflect(rd,set_normal(p));
				float3 LightDirection = ReflectionDirection;
				float3 LightColor = cubemap(ReflectionDirection);
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor);
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro).w;
					float3 material = map(ro).xyz;
					if (t < 0.001) 
						return float4 (lighting(ro,rd)*material,1.0); 
					else 
						ro+=t*rd; 
				}
				return float4(cubemap(rd),1.0);
			}

			structure vertex_shader (float4 vertex : POSITION)
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float3 ro = ps.world_vertex;
				float3 rd = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return raymarch (ro,rd);
			}

			ENDCG

		}
	}
}