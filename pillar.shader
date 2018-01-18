//https://github.com/przemyslawzaworski/Unity3D-CG-programming

Shader "Pillar"
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
		
			float3 mod(float3 x, float3 y)
			{
				return x - y * floor(x/y);
			}
			
			void radial(inout float2 p, float repetitions) 
			{
				float angle = 6.2831853071/repetitions;
				float a = atan2(p.y, p.x) + angle*0.5;
				float r = length(p);
				float c = floor(a/angle);
				a = mod(a,angle)-angle*0.5;
				p = float2(cos(a),sin(a))*r;
			}

			float cylinder( float3 p, float3 c,float2 h )
			{
				p=p-c;
				float2 d = abs(float2(length(p.xz),p.y)) - h;
				return min(max(d.x,d.y),0.0) + length(max(d,0.0));
			}

			float map (float3 p)
			{
				float d = cylinder(p,float3(0.0,0.0,0.0),float2(0.5,1.0));
				radial(p.xz,16.0);
				return max(d,-cylinder(p,float3(0.87,0.0,0.0),float2(0.4,1.1)) );
			}
			
			float4 lighting (float3 p, float e)
			{
				float4 a = float4 (0.1,0.1,0.1,1.0);       //ambient light color
				float4 b = float4(0.2,0.5,0.7,1.0);       //directional light color
				float3 l = normalize(float3(5,4,-12));   //directional light direction
				float c = (map(p+l*e)-map(p))/e;        //directional derivative equation
				return saturate(c)*b+a;                //return diffuse color
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001) return lighting(ro,0.001);
					ro+=t*rd;
				}
				return float4(0.7,0.7,0,1)*length(rd.xy);
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
				float2 iResolution = float2(1024,1024); 
				float2 FragCoord = ps.uv*iResolution;
				float2 uv = (2.0*FragCoord-iResolution)/iResolution.y;
				float3 ro = float3(0,0,-3);
				float3 rd = normalize(float3(uv,2.0));			
				return raymarch(ro,rd);
			}
			ENDCG
		}
	}
}