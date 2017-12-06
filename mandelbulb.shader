//original source: https://www.shadertoy.com/view/MdXSWn
//Licence Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
//translated from GLSL to HLSL by Przemyslaw Zaworski
//https://github.com/przemyslawzaworski/Unity3D-CG-programming
//Enable _isFullscreen for Graphics.Blit or disable for usage in a scene game object (like quad etc.)

Shader "Mandelbulb"
{
	Properties
	{
		[Toggle] _isFullscreen("Is fullscreen?", Float) = 1
	}
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
				float2 uv : TEXCOORD0;
			};
			
			float _isFullscreen,stime, ctime;
			float pixel_size = 0.0;	
			
			void ry(inout float3 p, float a)
			{  
				float c,s;float3 q=p;  
				c = cos(a); s = sin(a);  
				p.x = c * q.x + s * q.z;  
				p.z = -s * q.x + c * q.z; 
			}  

			float3 mb(float3 p) 
			{
				p.xyz = p.xzy;
				float3 z = p;
				float3 dz=float3(0,0,0);
				float power = 8.0;
				float r, theta, phi;
				float dr = 1.0;
				float t0 = 1.0;
				for(int i = 0; i < 7; ++i) 
				{
					r = length(z);
					if(r > 2.0) continue;
					theta = atan(z.y / z.x);
					phi = asin(z.z / r);	
					dr = pow(r, power - 1.0) * dr * power + 1.0;
					r = pow(r, power);
					theta = theta * power;
					phi = phi * power;	
					z = r * float3(cos(theta)*cos(phi),sin(theta)*cos(phi),sin(phi))+p;	
					t0 = min(t0, r);
				}
				return float3(0.5 * log(r) * r / dr, t0, 0.0);
			}

			float3 f(float3 p)
			{ 
				ry(p, _Time.g*0.2);
				return mb(p); 
			} 

			float softshadow(float3 ro, float3 rd, float k )
			{ 
				float akuma=1.0,h=0.0; 
				float t = 0.01;
				for(int i=0; i < 50; ++i)
				{ 
					h=f(ro+rd*t).x; 
					if(h<0.001)return 0.02; 
					akuma=min(akuma, k*h/t); 
					t+=clamp(h,0.01,2.0); 
				} 
				return akuma; 
			} 

			float3 nor( in float3 pos )
			{
				float3 eps = float3(0.001,0.0,0.0);
				return normalize( float3(
					f(pos+eps.xyy).x - f(pos-eps.xyy).x,
					f(pos+eps.yxy).x - f(pos-eps.yxy).x,
					f(pos+eps.yyx).x - f(pos-eps.yyx).x ) );
			}

			float3 intersect( in float3 ro, in float3 rd )
			{
				float t = 1.0;
				float res_t = 0.0;
				float res_d = 1000.0;
				float3 c, res_c;
				float max_error = 1000.0;
				float d = 1.0;
				float pd = 100.0;
				float os = 0.0;
				float step = 0.0;
				float error = 1000.0;   
				for( int i=0; i<48; i++ )
				{
					if( error < pixel_size*0.5 || t > 20.0 )
					{
					}
					else
					{         
						c = f(ro + rd*t);
						d = c.x;
						if(d > os)
						{
							os = 0.4 * d*d/pd;
							step = d + os;
							pd = d;
						}
						else
						{
							step =-os; os = 0.0; pd = 100.0; d = 1.0;
						}
						error = d / t;
						if(error < max_error) 
						{
							max_error = error;
							res_t = t;
							res_c = c;
						}       
						t += step;
					}
				}
				if( t>20.0/* || max_error > pixel_size*/ ) res_t=-1.0;
				return float3(res_t, res_c.y, res_c.z);
			}

			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float2 resolution;
				if (_isFullscreen)	
					resolution = _ScreenParams.xy;
				else 	
					resolution = float2(1024,1024);						
				float2 fragCoord = ps.uv*resolution;
				float2 q=fragCoord.xy/resolution.xy; 
				float2 uv = -1.0 + 2.0*q; 
				uv.x*=resolution.x/resolution.y;    
				pixel_size = 1.0/(resolution.x * 3.0);
				stime=0.7+0.3*sin(_Time.g*0.4); 
				ctime=0.7+0.3*cos(_Time.g*0.4); 
				float3 ta=float3(0.0,0.0,0.0); 
				float3 ro = float3(0.0, 3.*stime*ctime, 3.*(1.-stime*ctime));;
				float3 cf = normalize(ta-ro); 
				float3 cs = normalize(cross(cf,float3(0.0,1.0,0.0))); 
				float3 cu = normalize(cross(cs,cf)); 
				float3 rd = normalize(uv.x*cs + uv.y*cu + 3.0*cf);
				float3 sundir = normalize(float3(0.1, 0.8, 0.6)); 
				float3 sun = float3(1.64, 1.27, 0.99); 
				float3 skycolor = float3(0.6, 1.5, 1.0); 
				float3 bg = exp(uv.y-2.0)*float3(0.4, 1.6, 1.0);
				float halo=clamp(dot(normalize(float3(-ro.x, -ro.y, -ro.z)), rd), 0.0, 1.0); 
				float3 col=bg+float3(1.0,0.8,0.4)*pow(halo,17.0); 
				float t=0.0;
				float3 p=ro;  
				float3 res = intersect(ro, rd);
				if(res.x > 0.0)
				{
					p = ro + res.x * rd;
					float3 n=nor(p); 
					float shadow = softshadow(p, sundir, 10.0 );
					float dif = max(0.0, dot(n, sundir)); 
					float sky = 0.6 + 0.4 * max(0.0, dot(n, float3(0.0, 1.0, 0.0))); 
					float bac = max(0.3 + 0.7 * dot(float3(-sundir.x, -1.0, -sundir.z), n), 0.0); 
					float spe = max(0.0, pow(clamp(dot(sundir, reflect(rd, n)), 0.0, 1.0), 10.0)); 
					float3 lin = 4.5 * sun * dif * shadow; 
					lin += 0.8 * bac * sun; 
					lin += 0.6 * sky * skycolor; 
					lin += 3.0 * spe; 
					res.y = pow(clamp(res.y, 0.0, 1.0), 0.55);
					float3 tc0 = 0.5 + 0.5 * sin(3.0 + 4.2 * res.y + float3(0.0,0.5,1.0));
					col = lin *float3(0.9, 0.8, 0.6) *  0.2 * tc0;
					col=lerp(col,bg, 1.0-exp(-0.001*res.x*res.x)); 
				} 
				col=pow(clamp(col,0.0,1.0),float3(0.45,0.45,0.45)); 
				col=col*0.6+0.4*col*col*(3.0-2.0*col);
				float w = dot(col, float3(0.33,0.33,0.33));
				col=lerp(col, float3(w,w,w), -0.5);  
				col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
				return float4(col.xyz, 1.0);		
			}
			ENDCG
		}
	}
}