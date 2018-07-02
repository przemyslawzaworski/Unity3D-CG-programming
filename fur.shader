// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Original Source: https://www.shadertoy.com/view/4dcBRB

Shader "Fur"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			#define S(a, b, t) smoothstep(a, b, t)
			#define PI 3.14159265
			#define R3 1.732051
			
			float2 mod(float2 x, float2 y)
			{
				return x - y * floor(x/y);
			}
			
			float4 HexCoords(float2 uv) 
			{
				float2 s = float2(1, R3);
				float2 h = .5*s;
				float2 gv = s*uv; 
				float2 a = mod(gv, s)-h;
				float2 b = mod(gv+h, s)-h; 
				float2 ab = dot(a,a)<dot(b,b) ? a : b;
				float2 st = float2(atan2(ab.x, ab.y), length(ab));
				float2 id = gv-ab;
				return float4(st, id);
			}

			float GetT(float2 p, float2 a, float2 b) 
			{
				float2 ba = b-a;
				float2 pa = p-a;  
				return dot(ba, pa)/dot(ba, ba);
			}

			float2 ClosestPointSeg2D(float2 p, float2 a, float2 b) 
			{
				float2 ba = b-a;
				float2 pa = p-a;
				float t = dot(ba, pa)/dot(ba, ba);
				t = saturate(t);
				return a + ba*t;
			}

			float DistSeg2d(float2 uv, float2 a, float2 b) 
			{
				return length(uv-ClosestPointSeg2D(uv, a, b));
			}

			float N(float p) 
			{
				return frac(sin(p*6453.2)*3425.2);
			}

			float3 N23(float2 p) 
			{
				return frac(sin(float3(p.x*6454., p.y*746., (p.x+p.y)*64.2))*float3(876.4, 997.4, 654.2));
			}

			float N21(float2 p) 
			{
				p = frac(p*float2(123.45,234.56));
				p += dot(p, p+56.57);
				return frac(p.x*p.y);
			}

			float2 N22(float2 p) 
			{
				float n = N21(p);
				return float2(n, N21(p+n));
			}

			float2 N12(float p) 
			{
				float x = N(p);
				return float2(x, N(p*100.*x));
			}

			float N2(float2 p)
			{
				float3 p3  = frac(float3(p.xyx) * float3(443.897, 441.423, 437.195));
				p3 += dot(p3, p3.yzx + 19.19);
				return frac((p3.x + p3.y) * p3.z);
			}

			float N2(float x, float y) 
			{ 
				return N2(float2(x, y)); 
			}

			float SmoothNoise2(float2 uv) 
			{
				float2 id = floor(uv);
				float2 m = frac(uv);
				m = 3.*m*m - 2.*m*m*m;
				float top = lerp(N2(id.x, id.y), N2(id.x+1., id.y), m.x);
				float bot = lerp(N2(id.x, id.y+1.), N2(id.x+1., id.y+1.), m.x);
				return lerp(top, bot, m.y);
			}

			float Hash(in float2 p, in float scale) 
			{
				p = mod(p, scale);
				return frac(sin(dot(p, float2(27.16898, 38.90563))) * 5151.5473453);
			}

			float SmoothNoise(in float2 p, in float scale )
			{
				float2 f;
				p *= scale;
				f = frac(p);
				p = floor(p);
				f = f*f*(3.0-2.0*f);
				float res = lerp(lerp(Hash(p,scale),
					Hash(p + float2(1.0, 0.0), scale), f.x),
					lerp(Hash(p + float2(0.0, 1.0), scale),
					Hash(p + float2(1.0, 1.0), scale), f.x), f.y);
				return res;
			}

			float2 Rot2d(float2 p, float a) 
			{
				float s = sin(a);
				float c = cos(a);
				return float2(p.x*s-p.y*c, p.x*c+p.y*s);
			}

			#define NUM_STRANDS 150.
			#define STRAND_THICKNESS 1.
			#define FUR_SIZE 15.
			#define FUR_CURL 1.
			#define FUR_ROUGHNESS .13
			#define BASE_COL float3(1., .7, .3)
			#define SPOT_COL float3(.7, .3, .1)
			#define RING_COL float3(.2, .15, .1)
			#define MOTTLE .9

			float4 FurLayer(float2 uv, float2 offs, float2 grid, out float alpha) 
			{
				float2 gv = (uv-offs)*grid;
				float2 id = floor(gv);
				gv = frac(gv)-.5;
				float4 col = float4(0,0,0,0);
				col.rgb = N23(id);
				float2 a = float2(0,0);
				float n = SmoothNoise((floor((uv-offs)*grid)/grid+offs), 4.)*FUR_CURL;
				float r = (n + N21(id)*FUR_ROUGHNESS)*2.*PI;
				float2 b = Rot2d(float2(0,.4), r); 
				float t = saturate( GetT(gv, -b, b));
				float d = length(gv-(2.*b*t-b)); 
				float w = lerp(.004, .06, t)*STRAND_THICKNESS;
				float c = S(w, w*.8, d);
				alpha = S(w, 0., d)*c*S(.0, .5, t);
				col.a = (1.-t);
				col.rgb *= c*col.a;
				col.a *= col.a;
				return col;
			}

			float3 LeopardTex(float2 uv) 
			{
				float n = SmoothNoise(uv, 16.);
				n += SmoothNoise(uv, 32.)*.5;
				n/=1.5;
				float4 h = HexCoords(uv*5.);
				float2 o = N22(h.zw+76354.);
				float r = (.3+sin(h.x*3.+o.x)*.08*o.y);
				r *= lerp(.5, 1., frac(o.y*10.));
				float w = .4;
				float c = S(w, .0, abs(h.y-r));
				n = n*n + c;
				n = S(1., 1.2, n);
				float3 col = BASE_COL;
				col = lerp(col, SPOT_COL, S(r*1.5, .0, h.y));
				col = lerp(col, RING_COL, n);
				col *= 1.-SmoothNoise(uv, 50.)*MOTTLE;
				return col;
			}

			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				uv = uv*0.5;
				float t = _Time.g*0.3;
				uv = Rot2d(uv, t*.1);
				uv += t*.2;
				float2 grid = float2(FUR_SIZE,FUR_SIZE);
				float4 col = float4(0,0,0,0);
				for(float i=0.; i<NUM_STRANDS; i++) 
				{
					float2 offs = (N12(i)-.5);
					float alpha;
					float4 fur = FurLayer(uv, offs, grid, alpha);
					if(fur.a>col.a) col = lerp(col, fur, alpha);
				}
				col.rgb = float3(max(col.r,max(col.g,col.b)),max(col.r,max(col.g,col.b)),max(col.r,max(col.g,col.b)));
				col.rgb *= LeopardTex(uv*.5);
				return col*2.5;
			}
			ENDCG
		}
	}
}