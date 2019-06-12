Shader "Fluid Simulation" 
{
	SubShader 
	{
//------------------------------------------------------------------------------------------- CGINCLUDE

		CGINCLUDE
		#pragma vertex VSMain
		#pragma fragment PSMain
		
		sampler2D _Source, _Obstacles, _Velocity, _Temperature, _Density, _Pressure, _Divergence;			
		float2 _InverseSize, _Point;
		float _TimeStep, _Dissipation, _Alpha, _InverseBeta, _GradientScale;
		float _AmbientTemperature, _Sigma, _Kappa, _Radius, _Fill, _HalfInverseCellSize;				
			
		void VSMain(inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
    		vertex = UnityObjectToClipPos(vertex);
		}
		ENDCG
		
//------------------------------------------------------------------------------------------- Pass 0: Obstacle procedural texture
	
		Pass 
		{
			CGPROGRAM

			static const float2 vertices[4] = {{0.54f,0.86f},{0.83f,0.62f},{0.78f,0.81f},{0.64f,0.87f}};
			
			float polygon( float2 v[4], float2 p )
			{
				const int num = 4;
				float d = dot(p-v[0],p-v[0]);
				float s = 1.0;
				for( int i=0, j=num-1; i<num; j=i, i++ )
				{
					float2 e = v[j] - v[i];
					float2 w = p - v[i];
					float2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
					d = min( d, dot(b,b) );
					vector <bool,3> cond = { p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x };
					if( all(cond) || all(!(cond)) ) s*=-1.0;
				}   
				return step(sign(s*sqrt(d)),0.0);
			}			

			float circle(float2 p, float2 c, float r)
			{
				return step(length(p-c)-r, 0.0);
			}
			
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{	
				float a = polygon(vertices, uv);
				float b = circle(uv,float2(sin(_Time.g)*0.15+0.5,0.5),0.1);	
				float c = max(a,b);
				return float4(c.xxx,1);
			}
			
			ENDCG

		}
		
//------------------------------------------------------------------------------------------- Pass 1: Advection
	
		Pass 
		{
			CGPROGRAM
						
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{			
				float2 v = tex2D(_Velocity, uv).xy;			    
				float2 p = uv - (v * _InverseSize * _TimeStep);		    
				float4 result = _Dissipation * tex2D(_Source, p);		    
				float solid = tex2D(_Obstacles, uv).x;			    
				if(solid > 0.0) result = float4(0,0,0,0);			    
				return result;
			}
			
			ENDCG

		}	
	
//------------------------------------------------------------------------------------------- Pass 2: Buoyancy
	
		Pass 
		{

			CGPROGRAM
								
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float T = tex2D(_Temperature, uv).x;
				float2 V = tex2D(_Velocity, uv).xy;
				float D = tex2D(_Density, uv).x;			
				float2 result = V;			
				if(T > _AmbientTemperature) 
				{
					result += (_TimeStep * (T - _AmbientTemperature) * _Sigma - D * _Kappa ) * float2(sin(_Time.g), 1);
				}			    
				return float4(result, 0, 1);			    
			}
			
			ENDCG

		}

//------------------------------------------------------------------------------------------- Pass 3: Impulse
		
		Pass 
		{

			CGPROGRAM
									
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float d = distance(_Point, uv);			    
				float impulse = 0;			    
				if(d < _Radius) 
				{
					float a = (_Radius - d) * 0.5;
					impulse = min(a, 1.0);
				} 
				float source = tex2D(_Source, uv).x;			  
				return max(0, lerp(source, _Fill, impulse)).xxxx;
			}
			
			ENDCG

		}

//------------------------------------------------------------------------------------------- Pass 4: Divergence
		
		Pass 
    	{
			CGPROGRAM
						
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float2 vN = tex2D(_Velocity, uv + float2(0, _InverseSize.y)).xy;
				float2 vS = tex2D(_Velocity, uv + float2(0, -_InverseSize.y)).xy;
				float2 vE = tex2D(_Velocity, uv + float2(_InverseSize.x, 0)).xy;
				float2 vW = tex2D(_Velocity, uv + float2(-_InverseSize.x, 0)).xy;
				float bN = tex2D(_Obstacles, uv + float2(0, _InverseSize.y)).x;
				float bS = tex2D(_Obstacles, uv + float2(0, -_InverseSize.y)).x;
				float bE = tex2D(_Obstacles, uv + float2(_InverseSize.x, 0)).x;
				float bW = tex2D(_Obstacles, uv + float2(-_InverseSize.x, 0)).x;
				if(bN > 0.0) vN = 0.0;
				if(bS > 0.0) vS = 0.0;
				if(bE > 0.0) vE = 0.0;
				if(bW > 0.0) vW = 0.0;		
				float result = _HalfInverseCellSize * (vE.x - vW.x + vN.y - vS.y);		    
				return float4(result,0,0,1);
			}
			
			ENDCG

    	}
		
//------------------------------------------------------------------------------------------- Pass 5: Jacobi fluid solver
		
		Pass 
		{
			CGPROGRAM
			
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float pN = tex2D(_Pressure, uv + float2(0, _InverseSize.y)).x;
				float pS = tex2D(_Pressure, uv + float2(0, -_InverseSize.y)).x;
				float pE = tex2D(_Pressure, uv + float2(_InverseSize.x, 0)).x;
				float pW = tex2D(_Pressure, uv + float2(-_InverseSize.x, 0)).x;
				float pC = tex2D(_Pressure, uv).x;
				float bN = tex2D(_Obstacles, uv + float2(0, _InverseSize.y)).x;
				float bS = tex2D(_Obstacles, uv + float2(0, -_InverseSize.y)).x;
				float bE = tex2D(_Obstacles, uv + float2(_InverseSize.x, 0)).x;
				float bW = tex2D(_Obstacles, uv + float2(-_InverseSize.x, 0)).x;
				if(bN > 0.0) pN = pC;
				if(bS > 0.0) pS = pC;
				if(bE > 0.0) pE = pC;
				if(bW > 0.0) pW = pC;
				float bC = tex2D(_Divergence, uv).x;
				return (pW + pE + pS + pN + _Alpha * bC) * _InverseBeta;
			}
			
			ENDCG

    	}	
		
//------------------------------------------------------------------------------------------- Pass 6: Gradient
		
		Pass 
		{
			CGPROGRAM
			
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float pN = tex2D(_Pressure, uv + float2(0, _InverseSize.y)).x;
				float pS = tex2D(_Pressure, uv + float2(0, -_InverseSize.y)).x;
				float pE = tex2D(_Pressure, uv + float2(_InverseSize.x, 0)).x;
				float pW = tex2D(_Pressure, uv + float2(-_InverseSize.x, 0)).x;
				float pC = tex2D(_Pressure, uv).x;
				float bN = tex2D(_Obstacles, uv + float2(0, _InverseSize.y)).x;
				float bS = tex2D(_Obstacles, uv + float2(0, -_InverseSize.y)).x;
				float bE = tex2D(_Obstacles, uv + float2(_InverseSize.x, 0)).x;
				float bW = tex2D(_Obstacles, uv + float2(-_InverseSize.x, 0)).x;
				if(bN > 0.0) pN = pC;
				if(bS > 0.0) pS = pC;
				if(bE > 0.0) pE = pC;
				if(bW > 0.0) pW = pC;
				float2 oldV = tex2D(_Velocity, uv).xy;
				float2 grad = float2(pE - pW, pN - pS) * _GradientScale;
				float2 newV = oldV - grad; 
				return float4(newV,0,1);  
			}
			
			ENDCG

		}	
		
//------------------------------------------------------------------------------------------- Pass 7: Composition
		
		Pass 
		{
			CGPROGRAM
						
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float3 col = float3(1,1,1) * tex2D(_Source, uv).x;
				float obs = tex2D(_Obstacles, uv).x;
				float3 result = lerp(col, float3(1,1,1), obs);	
				return float4(result,1);
			}
			
			ENDCG

		}

//------------------------------------------------------------------------------------------- Pass 8: Shading
		
		Pass 
		{
			CGPROGRAM

			float ggx(float3 n, float3 v, float3 l, float rough, float f0)
			{
				float alpha = rough*rough;
				float3 h = normalize(v+l);
				float dnl = clamp(dot(n,l), 0.0, 1.0);
				float dnv = clamp(dot(n,v), 0.0, 1.0);
				float dnh = clamp(dot(n,h), 0.0, 1.0);
				float dlh = clamp(dot(l,h), 0.0, 1.0);
				float asqr = alpha*alpha;
				const float pi = 3.14159;
				float den = dnh*dnh*(asqr-1.0)+1.0;
				float d = asqr/(pi * den * den);
				dlh = pow(1.0-dlh, 5.0);
				float f = f0 + (1.0-f0)*dlh;
				float k = alpha/1.0;
				float vis = (1.0/(dnl*(1.0-k)+k))*(1.0/(dnv*(1.0-k)+k));
				return (dnl * d * f * vis);
			}
						
			float4 PSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0) : COLOR
			{
				float2 texel = _InverseSize;
				float2 n  = float2(0.0, texel.y);
				float2 e  = float2(texel.x, 0.0);
				float2 s  = float2(0.0, -texel.y);
				float2 w  = float2(-texel.x, 0.0);
				float d   = tex2D(_Source, uv).x;				
				if (d == 1.0) return float4(1,1,0,1);
				if (d == 0.0) return float4(0,0,0,1);
				float d_n  = tex2D(_Source, frac(uv+n)  ).x;
				float d_e  = tex2D(_Source, frac(uv+e)  ).x;
				float d_s  = tex2D(_Source, frac(uv+s)  ).x;
				float d_w  = tex2D(_Source, frac(uv+w)  ).x; 
				float d_ne = tex2D(_Source, frac(uv+n+e)).x;
				float d_se = tex2D(_Source, frac(uv+s+e)).x;
				float d_sw = tex2D(_Source, frac(uv+s+w)).x;
				float d_nw = tex2D(_Source, frac(uv+n+w)).x; 
				float dxn[3] = {d_ne - d_nw, d_e  - d_w, d_se - d_sw};
				float dyn[3] = {d_nw - d_sw, d_n  - d_s, d_ne - d_se};
				float dcn[3] = {0.5,1.0,0.5};				  
				float3 sp = float3(uv-0.5, 0);
				float3 light = float3(cos(_Time.g/2.0)*0.5, sin(_Time.g/2.0)*0.5, -8.0);
				float3 ld = light - sp;
				ld /= max(length(ld), 0.001);
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
						float3 bn = reflect(normalize(float3(10.0*dxy, -1.0)), float3(0,1,0));
						avd += w * bn;
						den += w;
					}
				}
				avd /= den;
				spec += ggx(avd, float3(0,1,0), ld, 0.7, 0.3);   
				float occ = 0.0;
				[unroll]
				for (float m = 1.0; m <= 10.0; m +=1.0) 
				{
					float dm = tex2Dbias(_Source, float4(uv, 0.0,m)).x;
					occ += smoothstep(-8.0, 2.0, (d - dm))/(m*m);
				}   
				occ = pow(occ / 1.5, 2.0);   
				return occ * float4(0.0,0,0.8,0) + 2.5*float4(0.9, 0.85, 0.8, 1)*spec;
			}
			
			ENDCG

		}		
//-------------------------------------------------------------------------------------------
		
	}
}