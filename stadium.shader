/*Set Main Camera to following position (0,30,-60).
In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). 
Add fly script to Main Camera. Play. 
Or just bind material with shader to any gameobject to create volumetric effect :) 
The MIT License https://opensource.org/licenses/MIT
Copyright © 2017 Przemyslaw Zaworski */

Shader "Stadium"
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
			
			float hash (float2 n) 
			{ 
				return frac(sin(dot(n, float2(12.9898, 4.1414)))*43758.5453);
			}

			float3 hash3( float2 p )
			{
				float3 q = float3(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)),dot(p,float2(419.2,371.9)));
				return frac(sin(q)*43758.5453);
			}

			float3 sky (float3 p) 
			{
				p.y = max(p.y,0.0);
				float k = 1.0-p.y;
				return float3(pow(k,20.0), pow(k,3.0), 0.3+k*0.2);
			}

			float capsule( float3 p, float3 a, float3 b, float r )
			{
				float3 pa = p - a, ba = b - a;
				float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
				return length( pa - ba*h ) - r;
			}

			float map_audience (float3 p)
			{
				float2 u = floor(p.xz*0.6);
				float h = hash(u);
				h = p.y - 0.1*length(p.xz)*pow(h,sin(_Time.g*h*20.0)+2.0); ;
				return max( min( h, 0.4), p.y-0.1*length(p.xz));
			}

			float map_cage (float3 p)
			{
				float a =  capsule(p,float3(-52.5,0,-3.6), float3(-52.5,3.7,-3.6), 0.2  );
				float b =  capsule(p,float3(-52.5,0,3.6), float3(-52.5,3.7,3.6), 0.2  );
				float c =  capsule(p,float3(-52.5,3.7,-3.6), float3(-52.5,3.7,3.6), 0.2  );
				float d =  capsule(p,float3(52.5,0,-3.6), float3(52.5,3.7,-3.6), 0.2  );
				float e =  capsule(p,float3(52.5,0,3.6), float3(52.5,3.7,3.6), 0.2  );
				float f =  capsule(p,float3(52.5,3.7,-3.6), float3(52.5,3.7,3.6), 0.2  );    
				return min(a,min(b,min(c,min(d,min(e,f)))));
			}

			float map (float3 p)
			{
				float2 u = floor(p.xz*50.0);
				float h = hash(u);
				h = p.y - 1.0 * h ;
				if (p.x<55.5 && p.x>-55.5 && p.z<37.0 && p.z>-37.0) return min(max(min(h,0.1),p.y-1.0),map_cage(p));
				else return map_audience(p);
			}
			
			float4 color (float3 ro)
			{
				float m = ro.y;
				float4 light_grass = float4(0.2,m*0.8,0.05,1);
				float4 dark_grass = float4(0.2,m*0.65,0.05,1);
				float4 Line = float4 (0.9,0.9,0.9,1.0);
				float3 d = hash3(floor(ro.xz*0.6));
				if (ro.x>=55.5 || ro.x<=-55.5 || ro.z>=37.0 || ro.z<=-37.0) return float4(d,1);
				if (ro.x<0.15 && ro.x>-0.15 && ro.z>-34.0 && ro.z<34.0 ) return Line;
				if (length(ro.xz)<9.0 && length(ro.xz)>8.7) return Line;
				if (ro.x>52.2 && ro.x<52.5 && ro.z>-34.0 && ro.z<34.0 ) return Line;
				if (ro.x<-52.2 && ro.x>-52.5 && ro.z>-34.0 && ro.z<34.0 ) return Line;
				if (ro.z>33.7 && ro.z<34.0 && ro.x>-52.2 && ro.x<52.5) return Line;
				if (ro.z<-33.7 && ro.z>-34.0  && ro.x>-52.2 && ro.x<52.5) return Line;   
				if (ro.x>-36.15 && ro.x<-35.85 && ro.z<20.0 && ro.z>-20.0 ) return Line;
				if (ro.x>-52.5 && ro.x<-36.15 && ro.z<20.15 && ro.z>19.85) return Line;
				if (ro.x>-52.5 && ro.x<-36.15 && ro.z>-20.15 && ro.z<-19.85) return Line;    
				if (ro.x>-47.15 && ro.x<-46.85 && ro.z<10.0 && ro.z>-10.0 ) return Line;
				if (ro.x>-52.5 && ro.x<-47.15 && ro.z<10.15 && ro.z>9.85) return Line;
				if (ro.x>-52.5 && ro.x<-47.15 && ro.z>-10.15 && ro.z<-9.85) return Line;
				if (length(ro.xz+float2(40.0,0.0))<9.0 && length(ro.xz+float2(40.0,0.0))>8.7 && ro.x>-36.0) return Line;
				if (ro.x<36.15 && ro.x>35.85 && ro.z<20.0 && ro.z>-20.0 ) return Line;
				if (ro.x<52.5 && ro.x>36.15 && ro.z<20.15 && ro.z>19.85) return Line;
				if (ro.x<52.5 && ro.x>36.15 && ro.z>-20.15 && ro.z<-19.85) return Line;    
				if (ro.x<47.15 && ro.x>46.85 && ro.z<10.0 && ro.z>-10.0 ) return Line;
				if (ro.x<52.5 && ro.x>47.15 && ro.z<10.15 && ro.z>9.85) return Line;
				if (ro.x<52.5 && ro.x>47.15 && ro.z>-10.15 && ro.z<-9.85) return Line;
				if (length(ro.xz-float2(40.0,0.0))<9.0 && length(ro.xz-float2(40.0,0.0))>8.7 && ro.x<36.0) return Line;
				if (length(ro.xz+float2(52.5,34.0))<3.0 && length(ro.xz+float2(52.5,34.0))>2.7 && ro.x>-52.5 && ro.z>-34.0) return Line;
				if (length(ro.xz-float2(52.5,34.0))<3.0 && length(ro.xz-float2(52.5,34.0))>2.7 && ro.x<52.5 && ro.z<34.0) return Line;
				if (length(ro.xz+float2(52.5,-34.0))<3.0 && length(ro.xz+float2(52.5,-34.0))>2.7 && ro.x>-52.5 && ro.z<34.0) return Line;
				if (length(ro.xz+float2(-52.5,34.0))<3.0 && length(ro.xz+float2(-52.5,34.0))>2.7 && ro.x<52.5 && ro.z>-34.0) return Line;
				if (fmod(abs(ro.x),10.0)<5.0) return dark_grass;
				else return light_grass;
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<256; i++)
				{
					float t = map(ro);
					if (ro.x>300.0 || ro.x<-300.0 || ro.z>300.0 || ro.z<-300.0) break;
					if ( t<0.001 ) return color(ro);
					ro+=t*rd;
				}
				return float4(sky(rd),1.0);
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