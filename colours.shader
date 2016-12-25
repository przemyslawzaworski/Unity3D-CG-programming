//Original source https://www.shadertoy.com/view/MtcXDr#
// Translated from GLSL to CG by Przemyslaw Zaworski

Shader "Colours"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			static const float n_delta =  0.015625;

			struct v2f
			{
				float4 screen_space_vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float rand(float3 n) { 
    			return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);
			}

			float perlin2(float3 n)
			{
    			float3 base = floor(n / n_delta) * n_delta;
    			float3 dd = float3(n_delta, 0.0, 0.0);
    			float tl = rand(base + dd.yyy), tr = rand(base + dd.xyy), bl = rand(base + dd.yxy), br = rand(base + dd.xxy);
    			float3 p = (n - base) / dd.xxx;
    			float t = lerp(tl, tr, p.x);
    			float b = lerp(bl, br, p.x);
    			return lerp(t, b, p.y);
			}

			float perlin3(float3 n)
			{
    			float3 base = float3(n.x, n.y, floor(n.z / n_delta) * n_delta);
    			float3 dd = float3(n_delta, 0.0, 0.0);
    			float3 p = (n - base) / dd.xxx;
    			float front = perlin2(base + dd.yyy);
    			float back = perlin2(base + dd.yyx);
    			return lerp(front, back, p.z);
			}

			float fbm(float3 n)
			{
    			float total = 0.0;
    			float m1 = 1.0;
    			float m2 = 0.1;
    			for (int i = 0; i < 5; i++)
    			{
        			total += perlin3(n * m1) * m2;
        			m2 *= 2.0;
        			m1 *= 0.5;
    			}
    			return total;
			}

			float nebula1(float3 uv)
			{
    			float n1 = fbm(uv * 2.9 - 1000.0);
    			float n2 = fbm(uv + n1 * 0.05);   
    			return n2;
			}

			float nebula2(float3 uv)
			{
			    float n1 = fbm(uv * 1.3 + 115.0);
			    float n2 = fbm(uv + n1 * 0.35);   
			    return fbm(uv + n2 * 0.17);
			}

			float nebula3(float3 uv)
			{
			    float n1 = fbm(uv * 3.0);
			    float n2 = fbm(uv + n1 * 0.15);   
			    return n2;
			}

			float3 nebula(float3 uv)
			{
    			uv *= 10.0;
				return nebula1(uv * 0.5) * float3(1.0, 0.0, 0.0) +
        		nebula2(uv * 0.4) * float3(0.0, 1.0, 0.0) +
        		nebula3(uv * 0.6) * float3(0.0, 0.0, 1.0);        
			}

			v2f vertex_shader (float4 local_vertex:position, float2 uv:texcoord0)
			{
				v2f o;
				o.screen_space_vertex = mul(UNITY_MATRIX_MVP,local_vertex);
				o.uv=uv;
				return o;
			}

			float4 pixel_shader (v2f i) : SV_TARGET
			{
				return float4(float3((nebula(float3(i.uv*5.1,_Time.g*0.1)*0.1)-1.0)),1.0);
			}

			ENDCG
		}
	}
}