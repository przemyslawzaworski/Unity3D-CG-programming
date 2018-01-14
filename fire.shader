//reference: https://www.shadertoy.com/view/XsVSDW
//Work in development... Need to fix camera movement, because I try to make
//another approach than proper solution included in 
//https://github.com/przemyslawzaworski/Unity3D-CG-programming/blob/master/raymarching_full_integration.shader

Shader "Fire"
{
	Properties
	{	
		flameColor ("Main Color", Color) = (1.0, 0.68, 0.32,0)
		[HideInInspector]
		_MainTex ("Texture", 2D) = "white" {}
		[HideInInspector]
		camera("camera",Vector) = (0.0,0.0,0.0,0.0)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
		
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
				float2 uv : TEXCOORD0;
			};
			
			sampler2D _MainTex;
			float4 camera, flameColor;
			static const float maxdist = 200.0;
			static const float3 flamePos = float3(0.0, 0.0, 0.0);
			
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
			
			float3x3 rotationZ( float z) 
			{
				return float3x3
				(
					cos(z),sin(z),0.0,
					-sin(z),cos(z),0.0,
					0.0,0.0,1.0
				);
			}
			
			float hash(float n)
			{
				return frac(sin(n)*753.5453123);
			}

			float noise(float3 x)
			{
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0-2.0*f);	
				float n = p.x + p.y*157.0 + 113.0*p.z;
				return lerp(lerp(lerp(hash(n+  0.0), hash(n+  1.0),f.x),
					lerp(hash(n+157.0), hash(n+158.0),f.x),f.y),
					lerp(lerp(hash(n+113.0), hash(n+114.0),f.x),
					lerp(hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
			}

			float map(float3 pos)
			{    
				float ft = _Time.g*40.0;   
				pos-= flamePos;
				pos.x+= 0.8 - 0.33;
				pos.y+= pos.x*pos.x*0.02 - 0.02;
				float3 q = pos*6.0;   
				q*= float3(1.0, 1.5, 1.0);
				q+= float3(ft, 0.0, 0.0);
				q.x+= 0.5*pos.x*noise(q + float3(30., 40., 50. + ft));
				q.y+= 0.5*pos.x*noise(q + float3(10., 30. + ft, 20.));
				q.z+= 0.5*pos.x*noise(q + float3(20., 60. - ft, 40. - ft));
				float dn = (-0.25 - 0.26*pos.x);
				pos.x+= dn*noise(q + float3(12., 3.+ ft, 16. - ft)) - dn/2.;
				pos.y+= dn*noise(q + float3(14., 7., 20.)) - dn/2.;
				pos.z+= dn*noise(q + float3(8. + ft*0.3, 22., 9.)) - dn/2.;
				float df = length(pos.yz) + 0.18*pos.x -0.04;
				return df;
			}

			float trace(float3 ro, float3 rd, float maxdist) 
			{
				float t = 0.02;
				float3 pos;   
				for (int i = 0; i < 64; ++i)
				{
					pos = rd*t + ro;
					float dist = map(pos);
					if (dist>maxdist || abs(dist)<0.002)
						break;
					t+= dist*0.75;
				}
				return t;
			}

			float3 getFlameDensColor(float3 pos, float3 ray, float s, float fi, int nbSteps)
			{  
				float d = 1.0;
				float f;
				float3 scol = float3(0.0,0.0,0.0);
				for (int i=0; i<70; i++)
				{
					if (i==nbSteps)
						break;
					pos+= ray*s;
					f = -map(pos);
					f = sign(f)*pow(abs(f),1.4);
					d = clamp(f, 0.0, 10.0);
					d*= smoothstep(-7.0, -4.0, pos.x)*smoothstep(-1.3, -1.5, pos.x)*(3. + 0.4*pos.x);
					d*= (0.7 + 20./(pow(abs(pos.x), 3.0) + 1.3));
					d*= 1.0 + 14.0*smoothstep(-1.88, -1.2, pos.x);
					scol+= d*flameColor.rgb;
				}    
				return clamp(scol*fi, 0.0, 1.5);
			}
    
			float4 combFlameCol(float4 col1, float4 col2)
			{
				float4 f = float4(1.5,1.5,1.5,1.0);
				return pow(pow(col1, f) + pow(clamp(col2, 0.0, 1.0), f), float4(0.66,0.66,0.66,1.0));   
			}

			float4 rendering(float3 tpos, float3 ray, float maxdist,float2 uv)
			{     
				float4 flamecol = float4(0.0,0.0,0.0,1.0);
				float tr = trace(tpos, ray, maxdist);
				float4 col = float4(0.0,0.0,0.0,1.0);
				float3 pos = tpos + tr*ray;
				if (tr<maxdist*0.95)
				{
					flamecol = float4(getFlameDensColor(pos,ray,0.07,0.5,70),1.0);                  
					tr = trace(tpos, ray, maxdist);
					pos = tpos + tr*ray;        
					col = tex2Dlod(_MainTex,float4(uv,0,0));
					return combFlameCol(col, flamecol);
				}
				else
				{  
					return tex2Dlod(_MainTex,float4(uv,0,0));
				}
			}
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				vs.uv=uv;
				return vs;
			}
		
			float4 pixel_shader (structure ps) : SV_TARGET
			{   
				float2 uv = (2.0*ps.screen_vertex.xy-_ScreenParams.xy)/_ScreenParams.y;
				float3 ro =  _WorldSpaceCameraPos.xyz;
				float3 p = mul (rotationZ(camera.z),float3(uv,2.0));
				p = mul (rotationX(camera.x),p);
				p = mul (rotationY(camera.y),p);
				float3 rd = normalize(p);	
				return rendering(ro, rd, maxdist, ps.uv); 
			}
			ENDCG
		}
	}
}