//Author: Przemyslaw Zaworski
//Usage: add 3D Object/Cube, set cube position (0,0,0) and scale(7,7,7). Bind material with shader to cube.
//Play with cube scale to change bounds. You can add another game object with reflection probe and see that
//volumetric material is visible by Unity Engine.

Shader "Volumetric Machine"
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
				float2 uv : TEXCOORD0;
				float3 world_vertex : TEXCOORD1;
			};
		
			float3 mod(float3 x, float3 y)
			{
				return x - y * floor(x/y);
			}
			
			void radial(inout float2 p) 
			{
				float a = mod(atan2(p.y, p.x) + .1963495,.39269908) - .1963495;
				p = float2(cos(a),sin(a))*length(p);
			}

			float capsule(float3 p, float3 a, float3 b, float r)
			{  
				float3 ab = b - a;
				return length((ab*clamp(dot(p - a, ab) / dot(ab, ab),0.,1.) + a) - p) -r ;
			}

			float map (float3 p)
			{
				p.y = mod(p.y + 1., 2.) - 1.;
				float2 d = abs(float2(length(p.xz),p.y)) - float2(.7,10.);
				float a = min(max(d.x,d.y),0.0) + length(max(d,0.)); 
				a=min(a,length(float2(length(p.xz)-1.2,p.y))-.35);
				radial(p.xz);
				float b = capsule(p,float3(.6,3,0),float3(.6,-3,0),.2);
				a=max(a,-b);
				p=float3(cos(_Time.g)*p.x-sin(_Time.g)*p.z,p.y,sin(_Time.g)*p.x+cos(_Time.g)*p.z);
				radial(p.xz);    
				float g = capsule(p,float3(2,-.5,0),float3(2,.5,0),.2);
				float e = capsule(p,float3(2,-.5,0),float3(1,-.5,0),.2);
				float f = capsule(p,float3(2,.5,0),float3(1,.5,0),.2);
				return min(a,min(min(g,e),f));
			}

			float4 raymarch (float3 p, float3 rd)
			{
					for (int i=0;i<128;i++)
					{
						float t = map (p);
						if (t<0.001) 
						{
							float n = 1.0-float(i)/float(128); 
							return float4(n*n,n*n,n*n,1.0);
						}      
						p+=t*rd;
					}
					discard;
					return 0;
			}
					
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);			
				return raymarch(worldPosition,viewDirection);
			}
			ENDCG
		}
	}
}