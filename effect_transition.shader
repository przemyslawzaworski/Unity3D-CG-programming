// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Effect Transition"
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

			float3x3 rotationX( float x) 
			{
				return float3x3
				(
					1.0,0.0,0.0,
					0.0,cos(x),sin(x),
					0.0,-sin(x),cos(x)
				);
			}	

			float3x3 rotationY( float y) 
			{
				return float3x3
				(
					cos(y),0.0,-sin(y),
					0.0,1.0,0.0,
					sin(y),0.0,cos(y)
				);
			}
			
			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return max(max(d.x,d.y),d.z);
			}
			
			float substraction( float d1, float d2 )
			{
				return max(-d1,d2);
			}		
			
			float map (float3 p)
			{
				p=mul(rotationX(_Time.g),p);
				float solid= substraction(cuboid(p,float3(0.0,0.0,0.0),float3(1.0,1.0,6.0)),cuboid(p,float3(0.0,0.0,0.0),float3(2.0,2.0,2.0)));
				solid=substraction(cuboid(p,float3(0.0,0.0,0.0),float3(1.0,6.0,1.0)),solid);
				return substraction(cuboid(p,float3(0.0,0.0,0.0),float3(6.0,1.0,1.0)),solid);
			}
			
			float map2 (float3 p)
			{
				p=mul(rotationY(_Time.g),p);
				return cuboid(p,float3(0.0,0.0,0.0),float3(2.0,2.0,2.0));
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float3 set_normal2 (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map2(p+x)-map2(p-x),map2(p+y)-map2(p-y),map2(p+z)-map2(p-z))); 
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight = float3 (0.1,0.1,0.1);
				float3 LightDirection = normalize(float3(50.0,10.0,-30.0));
				float3 LightColor = float3(1.0,1.0,1.0);
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight);
			}

			float3 lighting2 (float3 p)
			{
				float3 AmbientLight = float3 (0.1,0.1,0.1);
				float3 LightDirection = normalize(float3(50.0,10.0,-30.0));
				float3 LightColor = float3(1.0,1.0,0.0);
				float3 NormalDirection = set_normal2(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight);
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
				return float4(0.0,0.0,0.0,0.0);
			}
			
			float4 raymarch2 (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map2(ro);
					if (distance(ro,t*rd)>250) break;
					if (t < 0.001) return float4 (lighting2(ro),1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.5,0.0);
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
				float2 uv = ps.screen_vertex.xy / _ScreenParams.xy;
				float3 ro = ps.world_vertex;
				float3 rd = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				float a = fmod(floor(_Time.g),20.0);
				float b = fmod(_Time.g,20.0);	 
				float n = lerp (1.0-((b-10.0)*0.2),0.0,step(15.0,a));
				n = lerp(1.0,n,step(10.0,a));
				n = lerp(b*0.2,n,step(5.0,a));	
				float t = fmod(floor(uv.y*10.0),2.0);	
				return lerp(raymarch(ro,rd),raymarch2(ro,rd),min(max(sign(uv.x-n),0.0)*(1.0-abs(sign(t)))+max(sign(1.0-uv.x - n),0.0)*(1.0-abs(sign(t-1.0))),1.0));
			}

			ENDCG

		}
	}
}