// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//Original source https://www.shadertoy.com/view/Ms2SD1
//translated from GLSL to CG by Przemyslaw Zaworski
Shader "Ocean"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#include "UnityCG.cginc"
			
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _MainTex;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float4x4 _FrustumCornersES;
			uniform float4 _CameraWS;
			float4 _LightColor0; 
			
			struct custom_type
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			static const int num_steps = 8;
			static const float pi = 3.1415;
			static const float epsilon = 0.001;
			static const float epsilon_nrm	= 0.00001 ;
			static const int iter_geometry = 3;
			static const int iter_fragment = 5;
			static const float sea_height = 0.6;
			static const float sea_choppy = 4.0;
			static const float sea_speed = 0.8;
			static const float sea_freq = 0.16;
			static const float3 sea_base = float3(0.1,0.19,0.22);
			static const float3 sea_water_color = float3(0.8,0.9,0.6);
			static const float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);

			float hash (float2 p) 
			{
				float h = dot(p,float2(127.1,311.7));	
				return frac(sin(h)*43758.5453123);
			}

			float noise (float2 p) 
			{
				float2 i = floor( p );
				float2 f = frac( p );	
				float2 u = f*f*(3.0-2.0*f);
				return float(-1.0+2.0*lerp( lerp( hash( i + float2(0.0,0.0) ),hash( i + float2(1.0,0.0) ), u.x), lerp( hash( i + float2(0.0,1.0) ),hash( i + float2(1.0,1.0) ), u.x), u.y));
			}

			float diffuse(float3 n,float3 l,float p) 
			{
				return pow(dot(n,l) * 0.4 + 0.6,p);
			}

			float specular(float3 n,float3 l,float3 e,float s) 
			{    
				float nrm = (s + 8.0) / (3.1415 * 8.0);
				return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
			}

			float4 getSkyColor(float3 e) 
			{
				e.y = max(e.y,0.0);
				float3 ret;
				ret.x = pow(1.0-e.y,2.0);
				ret.y = 1.0-e.y;
				ret.z = 0.6+(1.0-e.y)*0.4;
				return float4(ret,0.0);
			}

			float sea_octave(float2 uv, float choppy) 
			{
				uv += noise(uv);        
				float2 wv = 1.0-abs(sin(uv));
				float2 swv = abs(cos(uv));    
				wv = lerp(wv,swv,wv);
				return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
			}

			float map(float3 p) 
			{
				float freq = sea_freq;
				float amp = sea_height;
				float choppy = sea_choppy;
				float2 uv = p.xz; uv.x *= 0.75;
				float d = 0.0; 
				float h = 0.0;    
				for(int i = 0; i < iter_geometry; i++)
				{        
					d = sea_octave((uv+float(_Time.g * sea_speed))*freq,choppy);
					d += sea_octave((uv-float(_Time.g * sea_speed))*freq,choppy);
					h += d * amp;        
					uv = mul(octave_m,uv); 
					freq *= 1.9; 
					amp *= 0.22;
				choppy = lerp(choppy,1.0,0.2);
				}
				return p.y - h;
			}

			float map_detailed(float3 p) 
			{
				float freq = sea_freq;
				float amp = sea_height;
				float choppy = sea_choppy;
				float2 uv = p.xz; 
				uv.x *= 0.75;   
				float d = 0.0; 
				float h = 0.0;    
				for(int i = 0; i < iter_fragment; i++) 
				{        
					d = sea_octave((uv+float(_Time.g * sea_speed))*freq,choppy);
					d += sea_octave((uv-float(_Time.g * sea_speed))*freq,choppy);
					h += d * amp;        
					uv = mul(octave_m,uv); 
					freq *= 1.9; 
					amp *= 0.22;
					choppy = lerp(choppy,1.0,0.2);
				}
				return p.y - h;
			}

			float4 getSeaColor(float3 p, float3 n, float3 l, float3 eye, float3 dist,float r) 
			{  
				float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;      
				float3 reflected = getSkyColor(reflect(eye,n));    
				float3 refracted = sea_base + diffuse(n,l,80.0) * sea_water_color * 0.12; 
				float3 color = lerp(refracted,reflected,fresnel);    
				float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
				color += sea_water_color * (p.y - sea_height) * 0.18 * atten;    
				color += float3(specular(n,l,eye,60.0),specular(n,l,eye,60.0),specular(n,l,eye,60.0));
				if (r ==1.0) return float4(color,1.0);
				else return float4(color,0.0);
			}

			float3 getNormal(float3 p, float eps) 
			{
				float3 n;
				n.y = map_detailed(p);    
				n.x = map_detailed(float3(p.x+eps,p.y,p.z)) - n.y;
				n.z = map_detailed(float3(p.x,p.y,p.z+eps)) - n.y;
				n.y = eps;
				return normalize(n);
			}

			float heightMapTracing(float3 ori, float3 dir, float s, out float3 p, out float result) 
			{ 
				float t = 0; 
				p=float3(0.0,0.0,0.0);
				result =0.0;
				float tm = 0.0;
				float tx = 1000.0;    
				float hx = map(ori + dir * tx);
				if(hx > 0.0) return tx;
				float hm = map(ori + dir * tm);    
				float tmid = 0.0;
				for(int i = 0; i < num_steps; i++) 
				{
					if (t >= s ) result = 0.0; else result=1.0;
					tmid = lerp(tm,tx, hm/(hm-hx));                   
					p = ori + dir * tmid;  				
					float hmid = map(p);
					t +=tmid;
					if(hmid < 0) 
					{
						tx = tmid;
						hx = hmid;
					} 
					else 
					{
						tm = tmid;
						hm = hmid;
					}
				}
				return tmid;
			}

			custom_type vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				custom_type vs;				
				half index = vertex.z;
				vertex.z = 0.1;				
				vs.pos = UnityObjectToClipPos(vertex);
				vs.uv = uv.xy;
				vs.ray = _FrustumCornersES[(int)index].xyz;
				vs.ray /= abs(vs.ray.z);
				vs.ray = mul(_CameraInvViewMatrix, vs.ray);
				return vs;
			}
			
			float4 pixel_shader (custom_type i) : SV_Target
			{
				float3 worldPosition = _CameraWS;
				float3 viewDirection = normalize(i.ray);
				float3 p = float3(5.0,23.0,1.0);
				float result ;
				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture,i.uv).r)*length(i.ray);
				float3 dist = heightMapTracing(worldPosition,viewDirection,depth,p,result) - worldPosition;
				float3 n = getNormal(p, dot(dist,dist) * epsilon_nrm);
				float3 light = normalize (float3 (100.0,100.0,100.0));
				float4 volume= float4 (lerp (getSkyColor(viewDirection), getSeaColor(p,n,light,viewDirection,dist,result), pow(smoothstep(0.0,-0.05,viewDirection.y),0.3)));
				float4 c = tex2D(_MainTex,i.uv);
				return lerp(c,volume,volume.w);
			}
			ENDCG
		}
	}
}