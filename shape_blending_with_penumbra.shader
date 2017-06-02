Shader "Shape Blending with Penumbra"
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
		
			float remap (float x, float a, float b, float c, float d)  
			{
				return (x-a)/(b-a)*(d-c) + c; 
			}
			
			static float time = remap(sin(_Time.g),-1.0,1.0,0.0,1.0);
			
			float plane(float3 p)
			{
				return p.y + 12.0f;
			}
			
			float sphere (float3 p,float3 c,float r)
			{
				return length (p-c)-r;
			}

			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return max(max(d.x,d.y),d.z);
			}
					
			float map (float3 p)
			{
				return lerp (min(sphere(p,0,1),plane(p)),min(cuboid(p,0,1),plane(p)),time) ;
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}
			
			float soft_shadow ( float3 ro, float3 rd, float mint, float maxt, float k )
			{
				float t = mint;
				float res = 1.0;
				for ( int i = 0; i < 128; ++i )
				{
					float h = map(ro + rd * t);
					if ( h < 0.001 ) return 0.0;
					res = min( res, k * h / t );
					t += h;
					if ( t > maxt ) break;
				}
				return res;
			}

			float3 lighting (float3 p)
			{	
				float3 LightPosition = float3( 94.0, 15.0, -50.0 );
				LightPosition .x = cos( _Time.g * 0.5 ) * 8.0;
				LightPosition .z = sin( _Time.g * 0.5 ) * 8.0;
				float3 LightDirection  = LightPosition - p;
				float LightDistance= length( LightDirection  );
				LightDirection  = normalize( LightDirection );
				float Shadow = soft_shadow( p, LightDirection , 0.0625, LightDistance,64.0);
				float3 AmbientLight = float3 (0.0,0.0,0.0);
				float3 LightColor = float3 (1.0,1.0,1.0);
				float3 NormalDirection = set_normal(p);
				return (saturate (dot(LightDirection , NormalDirection)) * LightColor + AmbientLight) * Shadow;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (distance(ro,t*rd)>250) break;
					if (t < 0.001) return float4 (lighting(ro),1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.0,1.0);
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