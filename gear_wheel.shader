//reference: https://www.shadertoy.com/view/Xds3zN
//Shader created by Przemyslaw Zaworski

Shader "Gear Wheel"
{
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			float3x3 rotationX (float x) 
			{
				return float3x3
				(
					1.0,0.0,0.0,
					0.0,cos(x),sin(x),
					0.0,-sin(x),cos(x)
				);
			}
				
			float3 mod(float3 x, float3 y)
			{
				return x - y * floor(x/y);
			}

			float map (float3 p) //gear wheel distance field
			{
				float2 t=float2(0.20,0.1);
				float2 q = float2(sqrt( p.x*p.x + p.z*p.z )-t.x,p.y);
				q = q*q; q = q*q;q = q*q;
				float s =  pow( q.x + q.y, 0.125 )-t.y;
				float3 h = float3(atan2(p.x,p.z)/6.2831853,p.y,0.02+0.5*length(p));
				float3 g = mod( h,float3(0.05f,1.0f,0.05f))-(0.5*float3(0.05,1.0,0.05)); //change "mod" to "fmod" to see difference
				float2 d = abs(float2(length(g.xz),g.y)) - float2(0.02,0.6);
				float u =  -(min(max(d.x,d.y),0.0) + abs(max(d.x,0.0)));  
				return max(s,u);
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.000,0.000);
				float3 y = float3 (0.000,0.001,0.000);
				float3 z = float3 (0.000,0.000,0.001);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float3 lighting (float3 p)
			{
				float3 AmbientLight = float3 (0.2,0.2,0.2);
				float3 LightDirection = normalize(float3(0,0,-20));
				float3 LightColor = float3 (0.7,0.7,0.7);
				float3 NormalDirection = set_normal(p);
				return clamp(dot(LightDirection,NormalDirection),0.0,1.0)*LightColor+AmbientLight;
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001) return float4(lighting(ro),1.0);
					ro+=t*rd;
				}
				return 0;
			}
					
			type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (type ps) : SV_TARGET
			{
				float2 resolution = float2(1024,1024); 
				float2 fragCoord = ps.uv*resolution;
				float2 uv = (2.0*fragCoord-resolution)/resolution.y;
				float3 worldPosition = float3(0,0.35,-0.75);
				float3 viewDirection = normalize(mul(rotationX(-0.5),float3(uv,2.0)));			
				return raymarch(worldPosition,viewDirection);
			}
			ENDCG
		}
	}
}