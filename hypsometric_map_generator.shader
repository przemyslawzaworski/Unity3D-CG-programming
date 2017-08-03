//I have published original version on https://www.shadertoy.com/view/ld2fRt
Shader "Hypsometric map generator"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float noise (float3 n) 
			{ 
				return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float perlin_a (float3 n)
			{
				float3 base = floor(n * 64.0) * 0.015625;
				float3 dd = float3(0.015625, 0.0, 0.0);
				float a = noise(base);
				float b = noise(base + dd.xyy);
				float c = noise(base + dd.yxy);
				float d = noise(base + dd.xxy);
				float3 p = (n - base) * 64.0;
				float t = lerp(a, b, p.x);
				float tt = lerp(c, d, p.x);
				return lerp(t, tt, p.y);
			}

			float perlin_b (float3 n)
			{
				float3 base = float3(n.x, n.y, floor(n.z * 64.0) * 0.015625);
				float3 dd = float3(0.015625, 0.0, 0.0);
				float3 p = (n - base) *  64.0;
				float front = perlin_a(base + dd.yyy);
				float back = perlin_a(base + dd.yyx);
				return lerp(front, back, p.z);
			}

			float fbm(float3 n)
			{
				float total = 0.0;
				float m1 = 1.0;
				float m2 = 0.1;
				for (int i = 0; i < 5; i++)
				{
					total += perlin_b(n * m1) * m2;
					m2 *= 2.0;
					m1 *= 0.5;
				}
				return total;
			}

			float3 heightmap (float3 n)
			{
				return float3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);
			}

			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float t = floor(_Time.g*0.33);
				float4 fragColor = float4(0,0,0,1);
				float color = clamp(float4(float3((heightmap(float3(ps.uv.xy*5.0,t)*0.02)-1.0)),1.0).r,0.0,1.0);
				if (color<0.1) fragColor=float4(0.77,0.90,0.98,1.0);
				else
				if (color<0.2) fragColor=float4(0.82,0.92,0.99,1.0);
				else
				if (color<0.3) fragColor=float4(0.91,0.97,0.99,1.0);
				else
				if (color<0.55) fragColor=float4(0.62,0.75,0.59,1.0);
				else
				if (color<0.65) fragColor=float4(0.86,0.90,0.68,1.0);
				else
				if (color<0.75) fragColor=float4(0.99,0.99,0.63,1.0);
				else
				if (color<0.85) fragColor=float4(0.99,0.83,0.59,1.0);
				else
				if (color<0.95) fragColor=float4(0.98,0.71,0.49,1.0);     
				else
				if (color<0.99) fragColor=float4(0.98,0.57,0.47,1.0);        
				else      
				fragColor=float4(0.79,0.48,0.43,1.0);            
				return fragColor;
			}
			
			ENDCG
		}
	}
}