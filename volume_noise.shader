Shader "Volume Noise"
{
	Properties
	{
		_density("Density",Range(0.1,1.0)) = 0.2	
		_scale("Scale",Range(1.0,5.0)) = 5.0
		_speed("Speed",Range(0.0,30.0)) = 0.0	
		_color ("Color", Color) = (0.6,0.3,0.0,1.0)	
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			float _density,_scale,_speed;
			float4 _color;
			
			float hash(float h)  //return pseudorandom number from 0..1 range
			{
				return frac(sin(h) * 43758.5453123);
			}

			float noise(float3 x)  //trilinear interpolation 
			{
				float3 p = floor(x);
				float3 i = frac(x);
				i = i * i * (3.0 - 2.0 * i);
				float n = p.x + p.y * 157.0 + 113.0 * p.z;
				float a = hash(n + 0.0);
				float b = hash(n + 1.0);
				float c = hash(n + 157.0);
				float d = hash(n + 158.0);
				float e = hash(n + 113.0);
				float f = hash(n + 114.0);
				float g = hash(n + 270.0);
				float h = hash(n + 271.0);
				return lerp(lerp(lerp(a,b,i.x),lerp(c,d,i.x),i.y),lerp(lerp(e,f,i.x),lerp(g,h,i.x),i.y),i.z);
			}

			float fbm(float3 p)   //Fractional Brownian Motion
			{
				float f = 0.0;
				f = 0.5000*noise(p);  p *= 2.01;
				f += 0.2500*noise(p);  p *= 2.02;
				f += 0.1250*noise(p);
				return f;
			}

			float smax(float a, float b, float k)  //polynomial smooth minimum
			{
				float h = saturate(0.5+0.5*(b-a)/k);
				return lerp(a,b,h)+k*h*(1.0-h);
			}

			float map(float3 p)  //3D distance field 
			{
				p = p / _scale;
				float d = (fbm(p)-_density)*_scale;
				float d2 = length(p.xy);
				return smax(d,-d2,0.1);
			}

			float3 set_normal (float3 p)   //calculate normal vector
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float4 lighting (float3 p,float3 rd)  //Lambert light model
			{
				return max(dot(-rd,set_normal(p)),0.0)*_color;
			}
			
			float4 raymarch (float3 ro, float3 rd)  //sphere tracing
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001) return lighting(ro,rd);
					ro+=t*rd;
				}
				discard;  //clear background
				return 0;
			}

			structure vertex_shader (float4 vertex:POSITION)  //vertex shader function
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul(unity_ObjectToWorld, vertex);
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET  //fragment shader function
			{		
				float3 ro = ps.world_vertex;
				float3 rd = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);				
				ro.z+=_Time.g*_speed;
				return raymarch(ro,rd);
			}

			ENDCG

		}
	}
}