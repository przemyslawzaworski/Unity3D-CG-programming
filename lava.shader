Shader "Lava"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			float hash (float3 n)   //generate pseudorandom number in range[0..1]
			{ 
				return frac(sin(dot(n,float3(42.32993,78.44481,94.99123)))*65536.32);
			}

			float noise (float3 n)   //bilinear base noise
			{
				float3 f = floor(n*64.0)*0.015625, t = float3(0.015625,0.0,0.0), p = (n-f)*64.0;
				float a = hash(f), b = hash(f+t.xyy), c = hash(f+t.yxy), d = hash(f+t.xxy);
				return lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
			}

			float perlin (float3 n)   //detail noise
			{
				float3 f = float3(n.xy,floor(n.z*64.0)*0.015625), t = float3(0.015625,0.0,0.0), p = (n-f)*64.0;
				float a = noise(f), b = noise(f+t.yyx);
				return lerp(a,b,p.z);
			}

			float fbm(float3 n)   //Fractional Brownian Motion
			{
				float t = 0.0, a = 1.0, b = 0.1;
				for (int i; i < 5; ++i) {t += perlin(n*a)*b; b *= 2.0; a *= 0.5;}
				return t;
			}

			float lava (float3 n)   //generate lava pattern
			{
				return fbm((5.0*n)+fbm((5.0*n)*3.0-float(1e3))*0.05);
			}
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				return float4(clamp(lava(float3(uv*3.0,_Time.g*0.05)*0.05)-1.0,0.1,0.9),0,0,1);
			}
			ENDCG
		}
	}
}