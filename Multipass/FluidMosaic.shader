// Original reference: https://www.shadertoy.com/view/MlVfDR
// Translated from GLSL to HLSL by Przemyslaw Zaworski

Shader "ShaderToy/FluidMosaic"
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
		
		void SetVertexShader (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}
		
		ENDCG

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM

			float4 T ( float2 U ) 
			{
				float2 R = iResolution.xy;
				return tex2D(_BufferD,U/R);
			}

			float X (float2 U0, float2 U, float2 U1, inout float4 Q, in float2 r) 
			{
				float N = 4.;
				float2 V = U + r, u = T(V).xy, V0 = V - u, V1 = V + u;
				float P = T (V0).z, rr = length(r);
				Q.xy -= r*(P-Q.z)/rr/N;
				return (0.5*(length(V0-U0)-length(V1-U1))+P)/N;
			}

			float ln (float2 p, float2 a, float2 b) 
			{
				return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.));
			}
		
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 Q:SV_TARGET)
			{
				float2 U = uv * iResolution.xy;
				float2 R = iResolution.xy;
				float2 U0 = U - T(U).xy,
					 U1 = U + T(U).xy;
				float P = 0.; Q = T(U0);
				float N = 4.;
				P += X (U0,U,U1,Q, float2( 1, 0) );
				P += X (U0,U,U1,Q, float2( 0,-1) );
				P += X (U0,U,U1,Q, float2(-1, 0) );
				P += X (U0,U,U1,Q, float2( 0, 1) );
				Q.z = P;
				if (iFrame < 2) Q = float4(0,0,0,0);
				if (U.x < 1.||U.y < 1.||R.x-U.x < 1.||R.y-U.y < 1.) Q.xy *= 0.;
				
				if (length(U-float2(0.1,0.5)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(.5,-.3);
				if (length(U-float2(0.7,0.3)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(-.6,.3);
				if (length(U-float2(0.2,0.2)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(.4,.6);
				if (length(U-float2(0.7,0.5)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(-.1,-.3);
				if (length(U-float2(0.5,0.6)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(0,-.7);
				
				float4 mo = tex2D(_BufferC,float2(0,0));
				float l = ln(U,mo.xy,mo.zw);
				if (mo.z > 0. && l < 10.) Q.xyz += float3((10.-l)*(mo.xy-mo.zw)/R.y,(10.-l)*(length(mo.xy-mo.zw)/R.y)*0.02);
  
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------
		
		Pass
		{ 
			CGPROGRAM

			float4 T ( float2 U ) {return tex2D(_BufferA,U/iResolution.xy);}
			float4 P ( float2 U ) {return tex2D(_BufferB,U/iResolution.xy);}

			void swap (float2 U, inout float4 Q, float2 u) 
			{
				float4 p = P(U+u);
				float dl = length(U-Q.xy) - length(U-p.xy);
				float e = .1;
				Q = lerp(Q,p,0.5+0.5*sign(floor(1e5*dl)));   
			}

			float ln (float2 p, float2 a, float2 b) 
			{ 
				return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.));
			}
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 Q:SV_TARGET)
			{	
				float2 U = uv * iResolution.xy;			
				float2 R = iResolution.xy;
				U = U-T(U).xy;
				Q = P(U);
				swap(U,Q,float2(1,0));
				swap(U,Q,float2(0,1));
				swap(U,Q,float2(0,-1));
				swap(U,Q,float2(-1,0));
				if ((length(Q.xy-float2(0.1,0.5)*R) < .02*R.y))
					Q.zw = float2(1,1);
				if ((length(Q.xy-float2(0.7,0.3)*R) < .02*R.y))
					Q.zw = float2(3,3);
				if ((length(Q.xy-float2(0.2,0.2)*R) < .02*R.y))
					Q.zw = float2(6,5);
				if (length(Q.xy-float2(0.7,0.5)*R) < .02*R.y)
					Q.zw = float2(2,7);
				if (length(Q.xy-float2(0.5,0.6)*R) < .02*R.y) 
					Q.zw = float2(5,4);
				float4 mo = tex2D(_BufferC,float2(0,0));
				if (mo.z > 0. && ln(U,mo.xy,mo.zw) < 10.) Q = float4(U,1,3.*sin(.4*_Time.g));
				Q.xy = Q.xy + T(Q.xy).xy;
				if (iFrame < 2) Q = float4(floor(U/10.+0.5)*10.,0.2,-.1);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
	
		Pass
		{ 
			CGPROGRAM
					
			float ln (float2 p, float2 a, float2 b) 
			{
				return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.));
			}
			float4 t (float2 v, int a, int b) 
			{
				float2 ur = iResolution.xy;
				return tex2D(_BufferA,frac((v+float2(a,b))/ur));}
				float4 t (float2 v) {
				float2 ur = iResolution.xy;
				return tex2D(_BufferA,frac(v/ur));
			}
			
			float area (float2 a, float2 b, float2 c) 
			{ 
				float A = length(b-c), B = length(c-a), C = length(a-b), s = 0.5*(A+B+C);
				return sqrt(s*(s-A)*(s-B)*(s-C));
			}

			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float4 p = tex2D(_BufferC,uv);
				if (iMouse.z>0.) 
				{
					if (p.z>0.) fragColor =  float4(iMouse.xy,p.xy);
					else fragColor =  float4(iMouse.xy,iMouse.xy);
				}
				else fragColor = float4(-iResolution.xy,-iResolution.xy);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM

			static const float N = 4.;

			float4 T ( float2 U ) 
			{
				float2 R = iResolution.xy;
				return tex2D(_BufferA,U/R);
			}
			
			float X (float2 U0, float2 U, float2 U1, inout float4 Q, in float2 r) 
			{
				float2 V = U + r, u = T(V).xy, V0 = V - u, V1 = V + u;
				float P = T (V0).z, rr = length(r);
				Q.xy -= r*(P-Q.z)/rr/N;
				return (0.5*(length(V0-U0)-length(V1-U1))+P)/N;
			}
			
			float ln (float2 p, float2 a, float2 b) 
			{ 
				return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.));
			}
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 Q:SV_TARGET)
			{
				float2 U = uv * iResolution.xy;
				float2 R = iResolution.xy;
				float2 U0 = U - T(U).xy, U1 = U + T(U).xy;
				float P = 0.; Q = T(U0);
				P += X (U0,U,U1,Q, float2( 1, 0) );
				P += X (U0,U,U1,Q, float2( 0,-1) );
				P += X (U0,U,U1,Q, float2(-1, 0) );
				P += X (U0,U,U1,Q, float2( 0, 1) );
				Q.z = P;
				if (iFrame < 2) Q = float4(0,0,0,0);
				if (U.x < 1.||U.y < 1.||R.x-U.x < 1.||R.y-U.y < 1.) Q.xy *= 0.;
				
				if (length(U-float2(0.1,0.5)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(.5,-.3);
				if (length(U-float2(0.7,0.3)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(-.6,.3);
				if (length(U-float2(0.2,0.2)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(.4,.6);
				if (length(U-float2(0.7,0.5)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(-.1,-.3);
				if (length(U-float2(0.5,0.6)*R) < .03*R.y) 
					Q.xy= Q.xy*.9+.1*float2(0,-.7);
				
				float4 mo = tex2D(_BufferC,float2(0,0));
				float l = ln(U,mo.xy,mo.zw);
				if (mo.z > 0. && l < 10.) Q.xyz += float3((10.-l)*(mo.xy-mo.zw)/R.y,(10.-l)*(length(mo.xy-mo.zw)/R.y)*0.02);
    
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			float4 T ( float2 U ) {return tex2D(_BufferA,U/iResolution.xy);}
			float4 P ( float2 U ) {return tex2D(_BufferB,U/iResolution.xy);}

			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 C:SV_TARGET)
			{
				float2 U = uv * iResolution.xy;
				float2 R = iResolution.xy;
				C = P(U);
				float2 n = P(U+float2(0,1)).xy,
					e = P(U+float2(1,0)).xy,
					s = P(U-float2(0,1)).xy,
					w = P(U-float2(1,0)).xy;
				float d = (length(n-C.xy)-1.+length(e-C.xy)-1.+length(s-C.xy)-1.+length(w-C.xy)-1.);
				float m1 = 0.0, m2 = 0.0;
				float p = smoothstep(2.5,2.,length(C.xy-U));
				C = 0.5-0.5*sin(.2*(1.+m1)*C.z*float4(1,1,1,1)+.4*(3.+m2)*C.w*float4(1,3,5,4));
				C *= 1.-clamp(.1*d,0.,1.);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}