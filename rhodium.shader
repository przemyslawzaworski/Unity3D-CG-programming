// Original source https://www.shadertoy.com/view/llK3Dy
// Translated from GLSL to CG by Przemyslaw Zaworski

Shader "Rhodium"
{
	Subshader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct v2f
			{
				float4 clip_space_position : SV_POSITION;
			};

			static float time = _Time.g;

			float sdBox(float3 p,float3 b)
			{
			  float3 d=abs(p)-b;
			  return min(max(d.x,max(d.y,d.z)),0.0)+length(max(d,0.0));
			}
			 
			void pR(inout float2 p,float a) 
			{
				p=cos(a)*p+sin(a)*float2(p.y,-p.x);
			}

			float noise(float3 p)
			{
				float3 ip=floor(p);
			    p-=ip; 
			    float3 s=float3(7,157,113);
			    float4 h=float4(0.0,s.yz,s.y+s.z)+dot(ip,s);
			    p=p*p*(3.0-2.0*p); 
			    h=lerp(frac(sin(h)*43758.5),frac(sin(h+s.x)*43758.5),p.x);
			    h.xy=lerp(h.xz,h.yw,p.y);
			    return lerp(h.x,h.y,p.z); 
			}

			float map(float3 p)
			{	
				p.z-=1.0;
			    p*=0.9;
			    pR(p.yz,abs(frac(0.05*time)-0.5)*20.0*1.0+0.4*p.x);
			    return sdBox(p+float3(0,sin(1.6*time),0),float3(20.0, 0.05, 1.2))-0.4*noise(8.0*p+3.0*abs(frac(0.05*time)-0.5)*20.0);
			}

			float3 calcNormal(float3 pos)
			{
			    float eps=0.0001;
				float d=map(pos);
				return normalize(float3(map(pos+float3(eps,0,0))-d,map(pos+float3(0,eps,0))-d,map(pos+float3(0,0,eps))-d));
			}


			float castRayx(float3 ro,float3 rd) 
			{
			    float function_sign=(map(ro)<0.0)?-1.0:1.0;
			    float precis=0.0001;
			    float h=precis*2.0;
			    float t=0.;
				for(int i=0;i<120;i++) 
				{
			        if(abs(h)<precis||t>12.0)break;
					h=function_sign*map(ro+rd*t);
			        t+=h;
				}
			    return t;
			}

			float refr(float3 pos,float3 lig,float3 dir,float3 nor,float angle,out float t2, out float3 nor2)
			{
			    float h=0.0;
			    t2=2.0;
				float3 dir2=refract(dir,nor,angle);  
			 	for(int i=0;i<50;i++) 
				{
					if(abs(h)>3.0) break;
					h=map(pos+dir2*t2);
					t2-=h;
				}
			    nor2=calcNormal(pos+dir2*t2);
			    return(0.5*clamp(dot(-lig,nor2),0.0,1.0)+pow(max(dot(reflect(dir2,nor2),lig),0.0),8.0));
			}

			float softshadow(float3 ro,float3 rd) 
			{
			    float sh=1.0;
			    float t=0.02;
			    float h=0.0;
			    for(int i=0;i<22;i++)  
				{
			        if(t>20.0)continue;
			        h=map(ro+rd*t);
			        sh=min(sh,4.0*h/t);
			        t+=h;
			    }
			    return sh;
			}

			v2f vertex_shader (float4 local_vertex:position)
			{
				v2f o;
				o.clip_space_position = mul(UNITY_MATRIX_MVP,local_vertex);
				return o;
			}

			float4 pixel_shader (v2f i) : SV_TARGET
			{ 
			   	float2 uv=i.clip_space_position.xy/_ScreenParams.xy; 
			    float2 p=uv*2.-1.;
			   	p.y=-1.0*p.y;
			    float wobble=(frac(0.1*(time-1.0))>=0.9)?frac(-time)*0.1*sin(30.0*time):0.0;
			    float3 dir = normalize(float3(2.0*i.clip_space_position.xy -_ScreenParams.xy, _ScreenParams.y));
			    float3 org = float3(0,2.*wobble,-3.0);  
			    float3 color = float3(0.0,0.0,0.0);
			    float3 color2 =float3(0.0,0.0,0.0);
			    float t=castRayx(org,dir);
				float3 pos=org+dir*t;
				float3 nor=calcNormal(pos);
			    float3 lig=normalize(float3(0.2,6.0,0.5));  
			    float depth=clamp((1.0-0.09*t),0.0,1.0);   
			    float3 pos2 = float3(0.0,0.0,0.0);
			    float3 nor2 = float3(0.0,0.0,0.0);
			    if(t<12.0)
			    {
			    	float cc = pow(max(dot(reflect(dir,nor),lig),0.0),16.0);
			    	color2 = float3(max(dot(lig,nor),0.)  +  float3(cc,cc,cc));
			    	color2 *=clamp(softshadow(pos,lig),0.0,1.0);            	
			       	float t2;
					color2.rgb +=refr(pos,lig,dir,nor,0.9, t2, nor2)*depth;
			        color2-=clamp(0.1*t2,0.0,1.0);	

				}      
			    float tmp = 0.;
			    float T = 1.0;
			    float intensity = 0.1*-sin(0.209*time+1.0)+0.05; 
				for(int i=0; i<128; i++)
				{
			        float density = 0.0; 
			        float nebula = noise(org+abs(frac(0.05*time)-.5)*20.0);
			        density=intensity-map(org+.5*nor2)*nebula;
					if(density>0.)
					{
						tmp = density / 128.;
			            T *= 1. -tmp * 100.;
						if( T <= 0.) break;
					}
					org += dir*0.078;
			    }    
				float3 basecol=float3(1./1. ,  1./4. , 1./16.);
			    T=clamp(T,0.0,1.5); 
			    color += basecol* exp(4.0*(0.5-T) - 0.8);
			    color2*=depth;
			    color2+= (1.0-depth)*noise(6.0*dir+0.3*time)*0.1;	
			    return float4(float3(1.*color+0.8*color2)*1.3,abs(0.67-depth)*2.+4.*wobble);
			}

			ENDCG
		}

		GrabPass { "_bufferA" }
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct v2f
			{
				float4 clip_space_position : SV_POSITION;
			};

			sampler2D _bufferA;
			float GA =2.399; 
			static float2x2 rot = float2x2(cos(GA),sin(GA),-sin(GA),cos(GA));

			float3 dof(sampler2D tex,float2 uv,float rad)
			{
				float3 acc=float3(0.0,0.0,0.0);
				float2 angle = float2(0.0,rad);
				float2 pixel=float2(0.002*_ScreenParams.y/_ScreenParams.x,0.002);
				rad=1.0;
				for (int j=0;j<80;j++)
				{  
				    rad += 1./rad;
					angle=mul(angle,rot);
				    float4 col=tex2D(tex,uv+pixel*(rad-1.0)*angle);
					acc+=col.xyz;
				}
				return acc/80.0;
			}


			v2f vertex_shader (float4 local_vertex:position)
			{
				v2f o;
				o.clip_space_position = mul(UNITY_MATRIX_MVP,local_vertex);
				return o;
			}

			float4 pixel_shader (v2f i) : SV_TARGET
			{ 
				float2 uv = i.clip_space_position.xy / _ScreenParams.xy;
				return float4 (dof(_bufferA,uv,tex2D(_bufferA,uv).w),1.0);
			}

			ENDCG
		}
	}
}