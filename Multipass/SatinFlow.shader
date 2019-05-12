// Original reference: https://www.shadertoy.com/view/Mstczn
// Translated from GLSL to HLSL by Przemyslaw Zaworski

Shader "Satin Flow"
{
	SubShader
	{

//-------------------------------------------------------------------------------------------
	
		CGINCLUDE
		#pragma vertex SetVertexShader
		#pragma fragment SetPixelShader
		
		sampler2D _BufferA;	
		sampler2D _BufferB;
		sampler2D _BufferC;	
		sampler2D _BufferD;			
		int iFrame;
		float4 iMouse;
		float4 iResolution;

		float2 hash( float2 p ) 
		{
			p = float2( dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)) );
			return -1.0 + 2.0*frac(sin(p)*43758.5453123);
		}

		float noise( in float2 p )
		{
			const float K1 = 0.366025404; // (sqrt(3)-1)/2;
			const float K2 = 0.211324865; // (3-sqrt(3))/6;
			float2 i = floor( p + (p.x+p.y)*K1 );
			float2 a = p - i + (i.x+i.y)*K2;
			float2 o = step(a.yx,a.xy);    
			float2 b = a - o + K2;
			float2 c = a - 1.0 + 2.0*K2;
			float3 h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
			float3 n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
			return dot( n, 70..xxx );	
		}

		float G1V(float dnv, float k)
		{
			return 1.0/(dnv*(1.0-k)+k);
		}

		float ggx(float3 n, float3 v, float3 l, float rough, float f0)
		{
			float alpha = rough*rough;
			float3 h = normalize(v+l);
			float dnl = clamp(dot(n,l), 0.0, 1.0);
			float dnv = clamp(dot(n,v), 0.0, 1.0);
			float dnh = clamp(dot(n,h), 0.0, 1.0);
			float dlh = clamp(dot(l,h), 0.0, 1.0);
			float f, d, vis;
			float asqr = alpha*alpha;
			const float pi = 3.14159;
			float den = dnh*dnh*(asqr-1.0)+1.0;
			d = asqr/(pi * den * den);
			dlh = pow(1.0-dlh, 5.0);
			f = f0 + (1.0-f0)*dlh;
			float k = alpha/1.0;
			vis = G1V(dnl, k)*G1V(dnv, k);
			float spec = dnl * d * f * vis;
			return spec;
		}
		
		void SetVertexShader (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}
		
		ENDCG

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM

			#define _G0 0.25
			#define _G1 0.125
			#define _G2 0.0625
			#define W0 20.0
			#define W1 0.5
			#define TIMESTEP 0.4
			#define ADVECT_DIST 1.0
			#define DV 0.70710678
			#define TWO_PI 6.28318530718
			#define PI 3.14159265359

			float nl(float x) 
			{
				return 1.0 / (1.0 + exp(W0 * (W1 * x - 0.5))); 
			}

			float3 gaussian(float3 x, float3 x_nw, float3 x_n, float3 x_ne, float3 x_w, float3 x_e, float3 x_sw, float3 x_s, float3 x_se) 
			{
				return _G0*x + _G1*(x_n + x_e + x_w + x_s) + _G2*(x_nw + x_sw + x_ne + x_se);
			}

			float3 advect(float2 ab, float2 vUv, float2 step) 
			{   
				float2 aUv = vUv - ab * ADVECT_DIST * step;   
				float2 n  = float2(0.0, step.y);
				float2 ne = float2(step.x, step.y);
				float2 e  = float2(step.x, 0.0);
				float2 se = float2(step.x, -step.y);
				float2 s  = float2(0.0, -step.y);
				float2 sw = float2(-step.x, -step.y);
				float2 w  = float2(-step.x, 0.0);
				float2 nw = float2(-step.x, step.y);
				float3 u =    tex2D(_BufferA, frac(aUv)).xyz;
				float3 u_n =  tex2D(_BufferA, frac(aUv+n)).xyz;
				float3 u_e =  tex2D(_BufferA, frac(aUv+e)).xyz;
				float3 u_s =  tex2D(_BufferA, frac(aUv+s)).xyz;
				float3 u_w =  tex2D(_BufferA, frac(aUv+w)).xyz;
				float3 u_nw = tex2D(_BufferA, frac(aUv+nw)).xyz;
				float3 u_sw = tex2D(_BufferA, frac(aUv+sw)).xyz;
				float3 u_ne = tex2D(_BufferA, frac(aUv+ne)).xyz;
				float3 u_se = tex2D(_BufferA, frac(aUv+se)).xyz;    
				return gaussian(u, u_nw, u_n, u_ne, u_w, u_e, u_sw, u_s, u_se);
			}

			float3 normz(float3 x) 
			{
				return x == float3(0.0, 0.0, 0.0) ? float3(0.0, 0.0, 0.0) : normalize(x);
			}

			float3 diagH(float3 x, float3 x_v, float3 x_h, float3 x_d) 
			{
				const float xd = sqrt(3.0) / 2.0;
				const float xi = 1.0 - xd;
				return 0.5 * ((x + x_v) * xi + (x_h + x_d) * xd);
			}

			float3 diagV(float3 x, float3 x_v, float3 x_h, float3 x_d) 
			{
				const float xd = sqrt(3.0) / 2.0;
				const float xi = 1.0 - xd;
				return 0.5 * ((x + x_h) * xi + (x_v + x_d) * xd);
			}
		
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;
				float2 vUv = uv;
				float2 texel = 1. / iResolution.xy;
				
				float3 n  = float3(0.0,   1.0, 0.0);
				float3 ne = float3(1.0,   1.0, 0.0);
				float3 e  = float3(1.0,   0.0, 0.0);
				float3 se = float3(1.0,  -1.0, 0.0);
				float3 s  = float3(0.0,  -1.0, 0.0);
				float3 sw = float3(-1.0, -1.0, 0.0);
				float3 w  = float3(-1.0,  0.0, 0.0);
				float3 nw = float3(-1.0,  1.0, 0.0);

				float3 u =    tex2D(_BufferB, frac(vUv)).xyz;
				float3 u_n =  tex2D(_BufferB, frac(vUv+texel*n.xy)).xyz;
				float3 u_e =  tex2D(_BufferB, frac(vUv+texel*e.xy)).xyz;
				float3 u_s =  tex2D(_BufferB, frac(vUv+texel*s.xy)).xyz;
				float3 u_w =  tex2D(_BufferB, frac(vUv+texel*w.xy)).xyz;
				float3 u_nw = tex2D(_BufferB, frac(vUv+texel*nw.xy)).xyz;
				float3 u_sw = tex2D(_BufferB, frac(vUv+texel*sw.xy)).xyz;
				float3 u_ne = tex2D(_BufferB, frac(vUv+texel*ne.xy)).xyz;
				float3 u_se = tex2D(_BufferB, frac(vUv+texel*se.xy)).xyz;
				
				float3 v =    tex2D(_BufferA, frac(vUv)).xyz;
				float3 v_n =  tex2D(_BufferA, frac(vUv+texel*n.xy)).xyz;
				float3 v_e =  tex2D(_BufferA, frac(vUv+texel*e.xy)).xyz;
				float3 v_s =  tex2D(_BufferA, frac(vUv+texel*s.xy)).xyz;
				float3 v_w =  tex2D(_BufferA, frac(vUv+texel*w.xy)).xyz;
				float3 v_nw = tex2D(_BufferA, frac(vUv+texel*nw.xy)).xyz;
				float3 v_sw = tex2D(_BufferA, frac(vUv+texel*sw.xy)).xyz;
				float3 v_ne = tex2D(_BufferA, frac(vUv+texel*ne.xy)).xyz;
				float3 v_se = tex2D(_BufferA, frac(vUv+texel*se.xy)).xyz;
				
				const float vx = 0.5;
				const float vy = sqrt(3.0) / 2.0;
				const float hx = vy;
				const float hy = vx;

				float di_n  = nl(distance(u_n + n, u));
				float di_w  = nl(distance(u_w + w, u));
				float di_e  = nl(distance(u_e + e, u));
				float di_s  = nl(distance(u_s + s, u));

				float di_nne = nl(distance((diagV(u, u_n, u_e, u_ne) + float3(+ vx, + vy, 0.0)), u));
				float di_ene = nl(distance((diagH(u, u_n, u_e, u_ne) + float3(+ hx, + hy, 0.0)), u));
				float di_ese = nl(distance((diagH(u, u_s, u_e, u_se) + float3(+ hx, - hy, 0.0)), u));
				float di_sse = nl(distance((diagV(u, u_s, u_e, u_se) + float3(+ vx, - vy, 0.0)), u));    
				float di_ssw = nl(distance((diagV(u, u_s, u_w, u_sw) + float3(- vx, - vy, 0.0)), u));
				float di_wsw = nl(distance((diagH(u, u_s, u_w, u_sw) + float3(- hx, - hy, 0.0)), u));
				float di_wnw = nl(distance((diagH(u, u_n, u_w, u_nw) + float3(- hx, + hy, 0.0)), u));
				float di_nnw = nl(distance((diagV(u, u_n, u_w, u_nw) + float3(- vx, + vy, 0.0)), u));
				
				float3 xy_n  = u_n + n - u;
				float3 xy_w  = u_w + w - u;
				float3 xy_e  = u_e + e - u;
				float3 xy_s  = u_s + s - u;
				
				float3 xy_nne = (diagV(u, u_n, u_e, u_ne) + float3(+ vx, + vy, 0.0)) - u;
				float3 xy_ene = (diagH(u, u_n, u_e, u_ne) + float3(+ hx, + hy, 0.0)) - u;
				float3 xy_ese = (diagH(u, u_s, u_e, u_se) + float3(+ hx, - hy, 0.0)) - u;
				float3 xy_sse = (diagV(u, u_s, u_e, u_se) + float3(+ vx, - vy, 0.0)) - u;
				float3 xy_ssw = (diagV(u, u_s, u_w, u_sw) + float3(- vx, - vy, 0.0)) - u;
				float3 xy_wsw = (diagH(u, u_s, u_w, u_sw) + float3(- hx, - hy, 0.0)) - u;
				float3 xy_wnw = (diagH(u, u_n, u_w, u_nw) + float3(- hx, + hy, 0.0)) - u;
				float3 xy_nnw = (diagV(u, u_n, u_w, u_nw) + float3(- vx, + vy, 0.0)) - u;
       
				float t0 = clamp(acos(dot(xy_n, xy_nne)   / (length(xy_n)   * length(xy_nne))), 0.0, PI);
				float t1 = clamp(acos(dot(xy_nne, xy_ene) / (length(xy_nne) * length(xy_ene))), 0.0, PI);
				float t2 = clamp(acos(dot(xy_ene, xy_e)   / (length(xy_ene) * length(xy_e)))  , 0.0, PI);
				float t3 = clamp(acos(dot(xy_e, xy_ese)   / (length(xy_e)   * length(xy_ese))), 0.0, PI);
				float t4 = clamp(acos(dot(xy_ese, xy_sse) / (length(xy_ese) * length(xy_sse))), 0.0, PI);
				float t5 = clamp(acos(dot(xy_sse, xy_s)   / (length(xy_sse) * length(xy_s)))  , 0.0, PI);
				float t6 = clamp(acos(dot(xy_s, xy_ssw)   / (length(xy_s)   * length(xy_ssw))), 0.0, PI);
				float t7 = clamp(acos(dot(xy_ssw, xy_wsw) / (length(xy_ssw) * length(xy_wsw))), 0.0, PI);
				float t8 = clamp(acos(dot(xy_wsw, xy_w)   / (length(xy_wsw) * length(xy_w)))  , 0.0, PI);
				float t9 = clamp(acos(dot(xy_w, xy_wnw)   / (length(xy_w)   * length(xy_wnw))), 0.0, PI);
				float t10= clamp(acos(dot(xy_wnw, xy_nnw) / (length(xy_wnw) * length(xy_nnw))), 0.0, PI);
				float t11= clamp(acos(dot(xy_nnw, xy_n)   / (length(xy_nnw) * length(xy_n)))  , 0.0, PI);
				
				float gcurve = TWO_PI - (t0+t1+t2+t3+t4+t5+t6+t7+t8+t9+t10+t11);

				float3 ma = di_nne * xy_nne + di_ene * xy_ene + di_ese * xy_ese + di_sse * xy_sse + di_ssw * xy_ssw + di_wsw * xy_wsw + di_wnw * xy_wnw + di_nnw * xy_nnw + di_n * xy_n + di_w * xy_w + di_e * xy_e + di_s * xy_s;

				float3 v_blur = gaussian(v, v_nw, v_n, v_ne, v_w, v_e, v_sw, v_s, v_se);
				
				float gcs = 2.87+10000.0*gcurve;
				
				float3 auv = advect(v.xy, vUv, texel);
				auv = advect(48.0 * gcs * (u - auv).xy, vUv, texel);
				
				float3 dv = auv + TIMESTEP * ma;

				if (iMouse.z > 0.0) 
				{
					float2 d = fragCoord.xy - iMouse.xy;
					float m = exp(-length(d) / 50.0);
					dv += m * normz(float3(d, 0.0));
				}
				
				if(iFrame < 10) 
				{
					float3 rnd = float3(noise(16.0 * vUv + 1.1), noise(16.0 * vUv + 2.2), noise(16.0 * vUv + 3.3));
					fragColor = float4(rnd,0);
				}
				else 
				{
					float ld = length(dv);
					dv = dv - 0.005* ld*ld*ld*normz(dv);
					fragColor = float4(dv, gcurve);
				}
  
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------
		
		Pass
		{ 
			CGPROGRAM

			#define _G0 0.25
			#define _G1 0.125
			#define _G2 0.0625
			#define TIMESTEP 0.1
			#define GSCALE -1000.0
			#define DV 0.70710678

			float3 gaussian(float3 x, float3 x_nw, float3 x_n, float3 x_ne, float3 x_w, float3 x_e, float3 x_sw, float3 x_s, float3 x_se) 
			{
				return _G0*x + _G1*(x_n + x_e + x_w + x_s) + _G2*(x_nw + x_sw + x_ne + x_se);
			}

			float4 gaussian(float4 x, float4 x_nw, float4 x_n, float4 x_ne, float4 x_w, float4 x_e, float4 x_sw, float4 x_s, float4 x_se) 
			{
				return _G0*x + _G1*(x_n + x_e + x_w + x_s) + _G2*(x_nw + x_sw + x_ne + x_se);
			}

			float3 normz(float3 x) 
			{
				return x == float3(0.0, 0.0, 0.0) ? float3(0.0, 0.0, 0.0) : normalize(x);
			}
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{	
				float2 fragCoord = uv * iResolution.xy;
				float2 vUv = uv;
				float2 texel = 1. / iResolution.xy;
				
				float3 n  = float3(0.0,   1.0, 0.0);
				float3 ne = float3(1.0,   1.0, 0.0);
				float3 e  = float3(1.0,   0.0, 0.0);
				float3 se = float3(1.0,  -1.0, 0.0);
				float3 s  = float3(0.0,  -1.0, 0.0);
				float3 sw = float3(-1.0, -1.0, 0.0);
				float3 w  = float3(-1.0,  0.0, 0.0);
				float3 nw = float3(-1.0,  1.0, 0.0);

				float3 u =    tex2D(_BufferB, frac(vUv)).xyz;
				float3 u_n =  tex2D(_BufferB, frac(vUv+texel*n.xy)).xyz;
				float3 u_e =  tex2D(_BufferB, frac(vUv+texel*e.xy)).xyz;
				float3 u_s =  tex2D(_BufferB, frac(vUv+texel*s.xy)).xyz;
				float3 u_w =  tex2D(_BufferB, frac(vUv+texel*w.xy)).xyz;
				float3 u_nw = tex2D(_BufferB, frac(vUv+texel*nw.xy)).xyz;
				float3 u_sw = tex2D(_BufferB, frac(vUv+texel*sw.xy)).xyz;
				float3 u_ne = tex2D(_BufferB, frac(vUv+texel*ne.xy)).xyz;
				float3 u_se = tex2D(_BufferB, frac(vUv+texel*se.xy)).xyz;
				
				float3 u_blur = gaussian(u, u_nw, u_n, u_ne, u_w, u_e, u_sw, u_s, u_se);
				
				float4 v =    tex2D(_BufferA, frac(vUv));
				float4 v_n =  tex2D(_BufferA, frac(vUv+texel*n.xy));
				float4 v_e =  tex2D(_BufferA, frac(vUv+texel*e.xy));
				float4 v_s =  tex2D(_BufferA, frac(vUv+texel*s.xy));
				float4 v_w =  tex2D(_BufferA, frac(vUv+texel*w.xy));
				float4 v_nw = tex2D(_BufferA, frac(vUv+texel*nw.xy));
				float4 v_sw = tex2D(_BufferA, frac(vUv+texel*sw.xy));
				float4 v_ne = tex2D(_BufferA, frac(vUv+texel*ne.xy));
				float4 v_se = tex2D(_BufferA, frac(vUv+texel*se.xy));
				
				float4 v_blur = gaussian(v, v_nw, v_n, v_ne, v_w, v_e, v_sw, v_s, v_se);
				
				float gc = v_blur.w;

				float3 du = u_blur + TIMESTEP * v.xyz;
				
				if(iFrame < 10) 
				{
					float3 rnd = float3(noise(16.0 * vUv + 1.1), noise(16.0 * vUv + 2.2), noise(16.0 * vUv + 3.3));
					fragColor = float4(rnd,0);
				}
				else 
				{
					float ld = length(du);
					du = du - 0.005* ld*ld*ld*normz(du);
					fragColor = float4(du, gc);
				}
    
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
	
		Pass
		{ 
			CGPROGRAM
					
			float laplacian(float2 fragCoord) 
			{
				float2 vUv = fragCoord.xy / iResolution.xy;
				float2 texel = 1. / iResolution.xy;

				float step_x = texel.x;
				float step_y = texel.y;
				float2 n  = float2(0.0, step_y);
				float2 ne = float2(step_x, step_y);
				float2 e  = float2(step_x, 0.0);
				float2 se = float2(step_x, -step_y);
				float2 s  = float2(0.0, -step_y);
				float2 sw = float2(-step_x, -step_y);
				float2 w  = float2(-step_x, 0.0);
				float2 nw = float2(-step_x, step_y);

				float4 uv =    tex2D(_BufferA, frac(vUv));
				float4 uv_n =  tex2D(_BufferA, frac(vUv+n));
				float4 uv_e =  tex2D(_BufferA, frac(vUv+e));
				float4 uv_s =  tex2D(_BufferA, frac(vUv+s));
				float4 uv_w =  tex2D(_BufferA, frac(vUv+w));
				float4 uv_nw = tex2D(_BufferA, frac(vUv+nw));
				float4 uv_sw = tex2D(_BufferA, frac(vUv+sw));
				float4 uv_ne = tex2D(_BufferA, frac(vUv+ne));
				float4 uv_se = tex2D(_BufferA, frac(vUv+se));
				
				float2 diff = float2(
					0.5 * (uv_e.x - uv_w.x) + 0.25 * (uv_ne.x - uv_nw.x + uv_se.x - uv_sw.x),
					0.5 * (uv_n.y - uv_s.y) + 0.25 * (uv_ne.y + uv_nw.y - uv_se.y - uv_sw.y)
				);
				
				return diff.x + diff.y;
			}

			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;	
				float la = length(tex2D(_BufferA, uv).zw);
				float lh = 0.9 * tex2Dbias(_BufferC, float4(uv, 0.0, 3.5)).w + 0.1 * la;
				fragColor = float4(-laplacian(fragCoord),0,0,lh);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM

			static const float a[121] = {
				1.2882849374994847E-4, 3.9883638750009155E-4, 9.515166750018973E-4, 0.0017727328875003466, 0.0025830133546736567, 0.002936729756271805, 0.00258301335467621, 0.0017727328875031007, 9.515166750027364E-4, 3.988363875000509E-4, 1.2882849374998886E-4,
				3.988363875000656E-4, 0.00122005053750234, 0.0029276701875229076, 0.005558204850002636, 0.008287002243739282, 0.009488002668845403, 0.008287002243717386, 0.005558204850002533, 0.002927670187515983, 0.0012200505375028058, 3.988363875001047E-4,
				9.515166750033415E-4, 0.0029276701875211478, 0.007226947743770152, 0.014378101312275642, 0.02243013709214819, 0.026345595431380788, 0.02243013709216395, 0.014378101312311218, 0.007226947743759695, 0.0029276701875111384, 9.515166750008558E-4,
				0.0017727328875040689, 0.005558204850002899, 0.014378101312235814, 0.030803252137257802, 0.052905271651623786, 0.06562027788638072, 0.052905271651324026, 0.03080325213733769, 0.014378101312364885, 0.005558204849979354, 0.0017727328874979902,
				0.0025830133546704635, 0.008287002243679713, 0.02243013709210261, 0.052905271651950365, 0.10825670746239457, 0.15882720544362505, 0.10825670746187367, 0.05290527165080182, 0.02243013709242713, 0.008287002243769156, 0.0025830133546869602,
				0.00293672975627608, 0.009488002668872716, 0.026345595431503218, 0.06562027788603421, 0.15882720544151602, 0.44102631192030745, 0.15882720544590473, 0.06562027788637015, 0.026345595431065568, 0.009488002668778417, 0.0029367297562566848,
				0.0025830133546700966, 0.008287002243704267, 0.022430137092024266, 0.05290527165218751, 0.10825670746234733, 0.1588272054402839, 0.1082567074615041, 0.052905271651381314, 0.022430137092484193, 0.00828700224375486, 0.002583013354686416,
				0.0017727328875014527, 0.005558204850013428, 0.01437810131221156, 0.03080325213737849, 0.05290527165234342, 0.06562027788535467, 0.05290527165227899, 0.03080325213731504, 0.01437810131229074, 0.005558204849973625, 0.0017727328874977803,
				9.515166750022218E-4, 0.002927670187526038, 0.0072269477437592895, 0.014378101312185454, 0.02243013709218059, 0.02634559543148722, 0.0224301370922164, 0.014378101312200022, 0.007226947743773282, 0.0029276701875125123, 9.515166750016471E-4,
				3.988363875000695E-4, 0.0012200505375021846, 0.002927670187525898, 0.005558204849999022, 0.008287002243689638, 0.009488002668901728, 0.008287002243695645, 0.0055582048500028335, 0.002927670187519828, 0.0012200505375025872, 3.988363874999818E-4,
				1.2882849374993535E-4, 3.9883638750004726E-4, 9.515166750034058E-4, 0.0017727328875029819, 0.0025830133546718525, 0.002936729756279661, 0.002583013354672541, 0.0017727328875033709, 9.515166750023861E-4, 3.988363874999023E-4, 1.2882849374998856E-4
			};
    
			static const float b[121] = {
				8673174.0, 1.5982146E7, 2.5312806E7, 3.4957296E7, 4.2280236E7, 4.5059652E7, 4.2280236E7, 3.4957296E7, 2.5312806E7, 1.5982146E7, 8673174.0,
				1.5982146E7, 2.9347785E7, 4.6341531E7, 6.3895356E7, 7.7184405E7, 8.2245411E7, 7.7184405E7, 6.3895356E7, 4.6341531E7, 2.9347785E7, 1.5982146E7,
				2.5312806E7, 4.6341531E7, 7.2970173E7, 1.00453608E8, 1.21193181E8, 1.29118131E8, 1.21193181E8, 1.00453608E8, 7.2970173E7, 4.6341531E7, 2.5312806E7,
				3.4957296E7, 6.3895356E7, 1.00453608E8, 1.38192768E8, 1.66613346E8, 1.77507756E8, 1.66613346E8, 1.38192768E8, 1.00453608E8, 6.3895356E7, 3.4957296E7,
				4.2280236E7, 7.7184405E7, 1.21193181E8, 1.66613346E8, 2.00759625E8, 2.13875721E8, 2.00759625E8, 1.66613346E8, 1.21193181E8, 7.7184405E7, 4.2280236E7,
				4.5059652E7, 8.2245411E7, 1.29118131E8, 1.77507756E8, 2.13875721E8, 2.27856753E8, 2.13875721E8, 1.77507756E8, 1.29118131E8, 8.2245411E7, 4.5059652E7,
				4.2280236E7, 7.7184405E7, 1.21193181E8, 1.66613346E8, 2.00759625E8, 2.13875721E8, 2.00759625E8, 1.66613346E8, 1.21193181E8, 7.7184405E7, 4.2280236E7,
				3.4957296E7, 6.3895356E7, 1.00453608E8, 1.38192768E8, 1.66613346E8, 1.77507756E8, 1.66613346E8, 1.38192768E8, 1.00453608E8, 6.3895356E7, 3.4957296E7,
				2.5312806E7, 4.6341531E7, 7.2970173E7, 1.00453608E8, 1.21193181E8, 1.29118131E8, 1.21193181E8, 1.00453608E8, 7.2970173E7, 4.6341531E7, 2.5312806E7,
				1.5982146E7, 2.9347785E7, 4.6341531E7, 6.3895356E7, 7.7184405E7, 8.2245411E7, 7.7184405E7, 6.3895356E7, 4.6341531E7, 2.9347785E7, 1.5982146E7,
				8673174.0, 1.5982146E7, 2.5312806E7, 3.4957296E7, 4.2280236E7, 4.5059652E7, 4.2280236E7, 3.4957296E7, 2.5312806E7, 1.5982146E7, 8673174.0
			};
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				const float _K0 = 20.0/6.0; 
				float2 texel = 1.0 / iResolution.xy;   
				float4 ac = float4(0,0,0,0);
				float4 bc = float4(0,0,0,0);
				float4 bcw = float4(0,0,0,0);
				for (int i = -5; i <= 5; i++) 
				{
					for (int j = -5; j <= 5; j++) 
					{
						int index = (j + 5) * 11 + (i + 5);
						float4 tx0 = tex2D(_BufferC, frac(uv + texel * float2(i,j)));
						float4 tx1 = tex2D(_BufferD, frac(uv + texel * float2(i,j)));
						ac  += -a[index] * tx0;
						bcw +=  b[index];
						bc  +=  b[index] * tx1;
					}
				}   
				bc /= bcw;
				fragColor = float4(ac + bc);   
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			#define BUMP 10.0

			float3 normz(float3 x) 
			{
				return x == float3(0,0,0) ? float3(0,0,0) : normalize(x);
			}

			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;
				float2 texel = 1. / iResolution.xy;

				float2 n  = float2(0.0, texel.y);
				float2 e  = float2(texel.x, 0.0);
				float2 s  = float2(0.0, -texel.y);
				float2 w  = float2(-texel.x, 0.0);

				float d   = tex2D(_BufferD, uv).x;

				float d_n  = tex2D(_BufferD, frac(uv+n)  ).x;
				float d_e  = tex2D(_BufferD, frac(uv+e)  ).x;
				float d_s  = tex2D(_BufferD, frac(uv+s)  ).x;
				float d_w  = tex2D(_BufferD, frac(uv+w)  ).x; 
				float d_ne = tex2D(_BufferD, frac(uv+n+e)).x;
				float d_se = tex2D(_BufferD, frac(uv+s+e)).x;
				float d_sw = tex2D(_BufferD, frac(uv+s+w)).x;
				float d_nw = tex2D(_BufferD, frac(uv+n+w)).x; 

				float dxn[3];
				float dyn[3];
				float dcn[3];
				
				dcn[0] = 0.5;
				dcn[1] = 1.0; 
				dcn[2] = 0.5;

				dyn[0] = d_nw - d_sw;
				dyn[1] = d_n  - d_s; 
				dyn[2] = d_ne - d_se;

				dxn[0] = d_ne - d_nw; 
				dxn[1] = d_e  - d_w; 
				dxn[2] = d_se - d_sw; 

				#define SRC_DIST 8.0
				float3 sp = float3(uv-0.5, 0);
				float3 light = float3(cos(_Time.g/2.0)*0.5, sin(_Time.g/2.0)*0.5, -SRC_DIST);
				float3 ld = light - sp;
				float lDist = max(length(ld), 0.001);
				ld /= lDist;
				float aDist = max(distance(float3(light.xy,0),sp) , 0.001);
				float atten = min(0.07/(0.25 + aDist*0.5 + aDist*aDist*0.05), 1.);
				float3 rd = normalize(float3(uv - 0.5, 1.));

				float spec = 0.0;
				float den = 0.0;
				float3 avd = float3(0,0,0);
				for(int i = 0; i < 3; i++) 
				{
					for(int j = 0; j < 3; j++) 
					{
						float2 dxy = float2(dxn[i], dyn[j]);
						float w = dcn[i] * dcn[j];
						float3 bn = reflect(normalize(float3(BUMP*dxy, -1.0)), float3(0,1,0));
						avd += w * bn;
						den += w;
					}
				}

				avd /= den;
				spec += ggx(avd, float3(0,1,0), ld, 0.7, 0.3);   
				float occ = 0.0;
				for (float m = 1.0; m <= 10.0; m +=1.0) 
				{
					float dm = tex2Dbias(_BufferD, float4(uv, 0.0,m)).x;
					occ += smoothstep(-8.0, 2.0, (d - dm))/(m*m);
				}   
				occ = pow(occ / 1.5, 2.0);   
				fragColor = occ * float4(0.9,0,0.05,0) + 2.5*float4(0.9, 0.85, 0.8, 1)*spec;
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}