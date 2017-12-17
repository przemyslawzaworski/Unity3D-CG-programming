//source: https://www.shadertoy.com/view/XlfBR7
//translated from ShaderToy to Unity by Przemyslaw Zaworski
//https://github.com/przemyslawzaworski
//usage: shader has access to UV coordinates, so can be applied to base game object

Shader "Tribute to Marc-Antoine Mathieu"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv: TEXCOORD0;
			};

			#define donut 30.0
			#define cell 4.0
			#define height 2.0
			#define thin 0.04
			#define radius 15.0
			#define speed 1.0
			#define STEPS 128.0
			#define VOLUME 0.001
			#define PI 3.14159
			#define TAU (2.*PI)
			#define time _Time.g

			float mod(float x, float y)
			{
				return x - y * floor(x/y);
			}
			
			float2 mod(float2 x, float2 y)
			{
				return x - y * floor(x/y);
			}

			float3 mod(float3 x, float3 y)
			{
				return x - y * floor(x/y);
			}

			float rng (float2 seed) 
			{ 
				return frac(sin(dot(seed*.1684,float2(54.649,321.547)))*450315.); 
			}
			
			float2x2 rot (float a) 
			{ 
				float c=cos(a),s=sin(a);
				return float2x2(c,-s,s,c); 
			}
			
			float sdSphere (float3 p, float r) 
			{ 
				return length(p)-r; 
			}
			
			float sdCylinder (float2 p, float r) 
			{ 
				return length(p)-r; 
			}
			
			float sdDisk (float3 p, float3 s) 
			{ 
				return max(max(length(p.xz)-s.x, s.y), abs(p.y)-s.z); 
			}
			
			float sdIso(float3 p, float r) 
			{ 
				return max(0.,dot(p,normalize(sign(p))))-r; 
			}
			
			float sdBox( float3 p, float3 b ) 
			{ 
				float3 d = abs(p) - b; 
				return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)); 
			}
			
			float sdTorus( float3 p, float2 t ) 
			{ 
				float2 q = float2(length(p.xz)-t.x,p.y); 
				return length(q)-t.y; 
			}
			
			float amod (inout float2 p, float count) 
			{ 
				float an = TAU/count; 
				float a = atan2(p.y,p.x)+an/2.; 
				float c = floor(a/an); 
				c = lerp(c,abs(c),step(count*.5,abs(c))); 
				a = mod(a,an)-an/2.; 
				p.xy = float2(cos(a),sin(a))*length(p); 
				return c; 
			}
			
			float amodIndex (float2 p, float count) 
			{ 
				float an = TAU/count; 
				float a = atan2(p.y,p.x)+an/2.; 
				float c = floor(a/an); 
				c = lerp(c,abs(c),step(count*.5,abs(c))); 
				return c; 
			}
			
			float repeat (float v, float c) 
			{ 
				return mod(v,c)-c/2.; 
			}
			
			float2 repeat (float2 v, float2 c) 
			{ 
				return mod(v,c)-c/2.; 
			}
			
			float3 repeat (float3 v, float c) 
			{ 
				return mod(v,c)-c/2.; 
			}
			
			float smoo (float a, float b, float r) 
			{ 
				return clamp(.5+.5*(b-a)/r, 0., 1.); 
			}
			
			float smin (float a, float b, float r) 
			{ 
				float h = smoo(a,b,r); 
				return lerp(b,a,h)-r*h*(1.-h); 
			}
			
			float smax (float a, float b, float r) 
			{ 
				float h = smoo(a,b,r); 
				return lerp(a,b,h)+r*h*(1.-h); 
			}
			
			float2 displaceLoop (float2 p, float r) 
			{ 
				return float2(length(p.xy)-r, atan2(p.y,p.x)); 
			}
			
			float windowCross (float3 pos, float4 size, float salt) 
			{
				float3 p = pos;
				float sx = size.x * (.6+salt*.4);
				float sy = size.y * (.3+salt*.7);
				float2 sxy = float2(sx,sy);
				p.xy = repeat(p.xy+sxy/2., sxy);
				float scene = sdBox(p, size.zyw*2.);
				scene = min(scene, sdBox(p, size.xzw*2.));
				scene = max(scene, sdBox(pos, size.xyw));
				return scene;
			}

			float window (float3 pos, float2 dimension, float salt) 
			{
				float thinn = .008;
				float depth = .04;
				float depthCadre = .06;
				float padding = .08;
				float scene = windowCross(pos, float4(dimension,thinn,depth), salt);
				float cadre = sdBox(pos, float3(dimension, depthCadre));
				cadre = max(cadre, -sdBox(pos, float3(dimension - padding, depthCadre*2.)));
				scene = min(scene, cadre);
				return scene;
			}

			float boxes (float3 pos, float salt) 
			{
				float3 p = pos;
				float ry = cell * .43*(.3+salt);
				float rz = cell * .2*(.5+salt);
				float salty = rng(float2(floor(pos.y/ry), floor(pos.z/rz)));
				pos.y = repeat(pos.y, ry);
				pos.z = repeat(pos.z, rz);
				float scene = sdBox(pos, float3(.1+.8*salt+salty,.1+.2*salt,.1+.2*salty));
				scene = max(scene, sdBox(p, float3(cell*.2,cell*.2,cell*.2)));
				return scene;
			}

			float map (float3 pos) 
			{
				float3 camOffset = float3(-5,0,0.);
				float scene = 1000.;
				float3 p = pos + camOffset;
				float segments = PI*radius;
				float indexX, indexY, salt;
				float2 seed;
				float3 pDonut = p;
				pDonut.x += donut;
				pDonut.y += radius;
				pDonut.xz = displaceLoop(pDonut.xz, donut);
				pDonut.z *= donut;
				pDonut.xzy = pDonut.xyz;
				pDonut.xz = mul(rot(time*.05*speed),pDonut.xz);
				p = pDonut;
				scene = min(scene, sdCylinder(p.xz, radius-height));
				p = pDonut;
				float py = p.y + time * speed;
				indexY = floor(py / (cell+thin));
				p.y = repeat(py, cell+thin);
				scene = min(scene, max(abs(p.y)-thin, sdCylinder(p.xz, radius)));
				amod(p.xz, segments);
				p.x -= radius;
				scene = min(scene, max(abs(p.z)-thin, p.x));
				p = pDonut;
				p.xz = mul(rot(PI/segments),p.xz);
				py = p.y + time * speed;
				indexY = floor(py / (cell+thin));
				p.y = repeat(py, cell+thin);
				indexX = amodIndex(p.xz, segments);
				amod(p.xz, segments);
				seed = float2(indexX, indexY);
				salt = rng(seed);
				p.x -= radius;
				float2 dimension = float2(.75,.5);
				p.x +=  dimension.x * 1.5;
				scene = max(scene, -sdBox(p, float3(dimension.x, .1, dimension.y)));
				scene = min(scene, window(p.xzy, dimension, salt));
				p = pDonut;
				py = p.y + cell/2. + time * speed;
				indexY = floor(py / (cell+thin));
				p.y = repeat(py, cell+thin);
				indexX = amodIndex(p.xz, segments);
				amod(p.xz, segments);
				seed = float2(indexX, indexY);
				salt = rng(seed);
				p.x -= radius;
				dimension.y = 1.5;
				p.x +=  dimension.x * 1.25;
				scene = max(scene, -sdBox(p, float3(dimension, .1)));
				scene = min(scene, window(p, dimension, salt));
				p = pDonut;
				p.xz = mul(rot(PI/segments),p.xz);
				py = p.y + cell/2. + time * speed;
				indexY = floor(py / (cell+thin));
				p.y = repeat(py, cell+thin);
				indexX = amodIndex(p.xz, segments);
				amod(p.xz, segments);
				seed = float2(indexX, indexY);
				salt = rng(seed);
				p.x -= radius - height;
				scene = min(scene, boxes(p, salt));
				return scene;
			}
			
			float getShadow (float3 pos, float3 at, float k) 
			{
				float3 dir = normalize(at - pos);
				float maxt = length(at - pos);
				float f = 01.;
				float t = VOLUME*50.;
				for (float i = 0.; i <= 1.; i += 1./15.) 
				{
					float dist = map(pos + dir * t);
					if (dist < VOLUME) return 0.;
					f = min(f, k * dist / t);
					t += dist;
					if (t >= maxt) break;
				}
				return f;
			}
			
			float3 getNormal (float3 p) 
			{ 
				float2 e = float2(.01,0); 
				return normalize(float3(map(p+e.xyy)-map(p-e.xyy),map(p+e.yxy)-map(p-e.yxy),map(p+e.yyx)-map(p-e.yyx))); 
			}

			void camera (inout float3 p) 
			{
				p.xz = mul(rot(PI/8.),p.xz);
				p.yz = mul(rot(PI/6.),p.yz);
			}
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float2 resolution = float2(800,480);
				float2 u = ps.uv.xy*resolution;
				float2 uv = (u.xy-.5*resolution.xy)/resolution.y;
				float3 eye = float3(0,0,-20.0);
				float3 ray = normalize(float3(uv, 1.3));
				camera(eye);
				camera(ray);
				float dither = rng(uv+frac(_Time.g));
				float3 pos = eye;
				float shade = 0.;
				for (float i = 0.; i <= 1.; i += 1./STEPS) 
				{
					float dist = map(pos);
					if (dist < VOLUME) 
					{
						shade = 1.-i;
						break;
					}
					dist *= .5 + .1 * dither;
					pos += ray * dist;
				}
				float3 light = float3(40.,100.,-10.);
				float shadow = getShadow(pos, light, 4.);
				float4 color = float4(1,1,1,1);
				color *= shade;
				color *= shadow;
				color = smoothstep(.0, .5, color);
				color.rgb = sqrt(color.rgb);
				return color;
			}

			ENDCG
		}
	}
}