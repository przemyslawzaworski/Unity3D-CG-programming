// Set Main Camera to following position (0,50,0).
Shader "Terrain procedural"
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

			float noise (float3 n) 
			{ 
				return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float perlin_a (float3 n)
			{
				float3 base = floor(n * 64.0) * 0.015625;
				float3 dd = float3(0.015625, 0.0, 0.0);
				float a = noise(base);
				float b = noise(base + dd.xyy);
				float c = noise(base + dd.yxy);
				float d = noise(base + dd.xxy);
				float3 p = (n - base) * 64.0;
				float t = lerp(a, b, p.x);
				float tt = lerp(c, d, p.x);
				return lerp(t, tt, p.y);
			}

			float perlin_b (float3 n)
			{
				float3 base = float3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
				float3 dd = float3(0.015625, 0.0, 0.0);
				float3 p = (n - base) *  64.0;
				float front = perlin_a(base + dd.yyy);
				float back = perlin_a(base + dd.yyx);
				return lerp(front, back, p.z);
			}

			float fbm(float3 n)
			{
				float total = 0.0;
				float m1 = 1.0;
				float m2 = 0.1;
				for (int i = 0; i < 5; i++)
				{
					total += perlin_b(n * m1) * m2;
					m2 *= 2.0;
					m1 *= 0.5;
				}
				return total;
			}

			float3 heightmap (float3 n)
			{
				return float3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);
			}
			
			float map (float3 p)
			{
				return p.y-32.0*float4(float3((heightmap(float3(p.xz*0.005,1.0)*0.1)-1.0)),1.0).r;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<512; i++)
				{
					float t = map(ro);
					if (ro.x>300.0 || ro.x<-300.0 || ro.z>300.0 || ro.z<-300.0) break;
					if ( t<0.0001 ) return float4(5.0/ro.y,0.0,0.0,1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.0,0.0);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
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