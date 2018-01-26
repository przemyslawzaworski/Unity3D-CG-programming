Shader "Radial Blur 2k18"
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			float hash(float3 n) 
			{ 
				return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float noise(float3 n)
			{
				float3 base = floor(n * 64.0) * 0.015625;
				float3 dd = float3(0.015625, 0.0, 0.0);
				float a = hash(base);
				float b = hash(base + dd.xyy);
				float c = hash(base + dd.yxy);
				float d = hash(base + dd.xxy);
				float3 p = (n - base) * 64.0;
				float t = lerp(a, b, p.x);
				float tt = lerp(c, d, p.x);
				return lerp(t, tt, p.y);
			}

			float fbm(float3 n)
			{
				float total = 0.0;
				float m1 = 1.0;
				float m2 = 0.1;
				for (int i = 0; i < 5; i++)
				{
					total += noise(n * m1) * m2;
					m2 *= 2.0;
					m1 *= 0.5;
				}
				return total;
			}

			float heightmap (float3 n)
			{
				return fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05);
			}

			float3 surface(float2 uv)
			{
				float color = clamp(heightmap(float3(uv.xy*5.0,2.0)*0.02)-1.0,0.0,1.0);
				if (color<0.1) return float3(0.35,0.40,0.44);
				else if (color<0.2) return float3(0.29,0.32,0.35);
				else if (color<0.3) return float3(0.20,0.21,0.22);
				else if (color<0.55) return float3(0.09,0.11,0.09);
				else if (color<0.65) return float3(0.18,0.19,0.14);
				else if (color<0.75) return float3(0.52,0.52,0.33);
				else if (color<0.85) return float3(0.45,0.37,0.27);
				else if (color<0.95) return float3(0.34,0.25,0.17);     
				else if (color<0.99) return float3(0.59,0.34,0.29);        
				else return float3(0.14,0.09,0.08); 
			}

			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 resolution = float2(1024,1024); 
				float2 fragCoord = ps.uv*resolution;
				float2 p = (2.0*fragCoord-resolution)/resolution.y;		
				float3  col = float3(0.0,0.0,0.0);
				float2  d = (float2(0.0,0.0)-p)/74.0;
				float w = 1.0;
				float2  s = p;
				for( int i=0; i<74; i++ )
				{
					float3 res = surface(float2(s.x+_Time.g,s.y)+sin(_Time.g)) ;
					col += w*smoothstep( 0.0, 1.0, res );
					w *= .985;
					s += d;
				}
				col = col * 4.5 / 74.0;
				return float4( col.xyz, 1.0 );
			}
			ENDCG
		}
	}
}