// Original reference: https://www.shadertoy.com/view/XddGDf
// Converted from GLSL to HLSL by Przemyslaw Zaworski

Shader "PseudoFluidSystem"
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
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
			
				if (iFrame < 60) 
				{
					fragColor = float4(.5,.5,0.,0.);
					return;
				}
    
				if (iMouse.w < 1.) 
				{
					if (sin(_Time.g*.2) > .2) 
					{
						if (length(float2(sin(_Time.g*.44)*.8,cos(_Time.g*.16)*.8)-uv*2.+1.) < .1) 
						{
							fragColor = float4( (normalize(uv-.5)*-.5) *.5+.5,0.,0.);
							return;
						}
					}
				}
				else 
				{
					if (iMouse.w > 0. && length(iMouse.xy/iResolution.xy-uv) < .05) 
					{
						fragColor = float4((-normalize(iMouse.xy/iResolution.xy-uv))*.5+.5,0.,0.);
						return;
					}
				}
				float2 odRes = 1./iResolution.xy;     
				float4 cLeft = tex2D(_BufferA, frac(uv-float2(odRes.x,0.)))*2.-1.,
				cRight = tex2D(_BufferA, frac(uv+float2(odRes.x,0.)))*2.-1.,
				cUp = tex2D(_BufferA, frac(uv-float2(0.,odRes.y)))*2.-1.,
				cDown = tex2D(_BufferA, frac(uv+float2(0.,odRes.y)))*2.-1.,
				cTopLeft = tex2D(_BufferA, frac(uv+float2(-odRes.x,-odRes.y)))*2.-1.,
				cTopRight = tex2D(_BufferA, frac(uv+float2(odRes.x,-odRes.y)))*2.-1.,
				cBottomLeft = tex2D(_BufferA, frac(uv+float2(-odRes.x,odRes.y)))*2.-1.,
				cBottomRight = tex2D(_BufferA, frac(uv+float2(odRes.x,odRes.y)))*2.-1.;  
				float4 c = float4(0,0,0,0);
				for (float x = -1.; x < 2.; x++) 
				{
					for (float y = -1.; y < 2.; y++) 
					{
						float2 v = float2(x,y);
						if (length(v) == 0.) continue;           
						c.xy -= (tex2Dlod(_BufferB, float4(uv+odRes*v,0,0)).xy*2.-1.)*0.5;
						c.xy += (tex2Dlod(_BufferC, float4(uv+odRes*v,0,0)).xy*2.-1.)*0.25;
					}
				}
				c.xy /= 3.*3.*2.-2.;   
				c += cLeft*(1.+dot(float2(1.,0.),cLeft.xy));
				c += cRight*(1.+dot(float2(-1.,0.),cRight.xy));
				c += cUp*(1.+dot(float2(0.,1.),cUp.xy));
				c += cDown*(1.+dot(float2(0.,-1.),cDown.xy));
				c += cTopLeft*(1.+dot(normalize(float2(1.,1.)),cTopLeft.xy));
				c += cTopRight*(1.+dot(normalize(float2(-1.,1.)),cTopRight.xy));
				c += cBottomLeft*(1.+dot(normalize(float2(1.,-1.)),cBottomLeft.xy));
				c += cBottomRight*(1.+dot(normalize(float2(-1.,-1.)),cBottomRight.xy));
				c.xy /= 8.;
				c.xy = clamp(c.xy, -1., 1.);
				c.xy = c.xy*.5+.5;  
				fragColor = c;
 
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
	
		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				if (iFrame < 60) 
				{
					fragColor = float4(.5,.5,0.,0.);
					return;
				}   
				float2 odRes = 1./iResolution.xy;
				float4 cLeft = tex2D(_BufferB, frac(uv-float2(odRes.x,0.)))*2.-1.,
				cRight = tex2D(_BufferB, frac(uv+float2(odRes.x,0.)))*2.-1.,
				cUp = tex2D(_BufferB, frac(uv-float2(0.,odRes.y)))*2.-1.,
				cDown = tex2D(_BufferB, frac(uv+float2(0.,odRes.y)))*2.-1.,
				cTopLeft = tex2D(_BufferB, frac(uv+float2(-odRes.x,-odRes.y)))*2.-1.,
				cTopRight = tex2D(_BufferB, frac(uv+float2(odRes.x,-odRes.y)))*2.-1.,
				cBottomLeft = tex2D(_BufferB, frac(uv+float2(-odRes.x,odRes.y)))*2.-1.,
				cBottomRight = tex2D(_BufferB, frac(uv+float2(odRes.x,odRes.y)))*2.-1.;    
				float4 c = float4(0,0,0,0);
				for (float x = -1.; x < 2.; x++) 
				{
					for (float y = -1.; y < 2.; y++) 
					{
						float2 v = float2(x,y);
						if (length(v) == 0.) continue;           
						c.xy -= length(tex2Dlod(_BufferA, float4(uv+odRes*v,0,0)).xy*2.-1.)*normalize(v);
					}
				}
				c.xy /= 3.*3.-1.;   
				c += cLeft*(1.+dot(float2(1.,0.),cLeft.xy));
				c += cRight*(1.+dot(float2(-1.,0.),cRight.xy));
				c += cUp*(1.+dot(float2(0.,1.),cUp.xy));
				c += cDown*(1.+dot(float2(0.,-1.),cDown.xy));
				c += cTopLeft*(1.+dot(normalize(float2(1.,1.)),cTopLeft.xy));
				c += cTopRight*(1.+dot(normalize(float2(-1.,1.)),cTopRight.xy));
				c += cBottomLeft*(1.+dot(normalize(float2(1.,-1.)),cBottomLeft.xy));
				c += cBottomRight*(1.+dot(normalize(float2(-1.,-1.)),cBottomRight.xy));
				c /= 8.1;
				c.xy = clamp(c.xy, -1., 1.);
				c = c*.5+.5;  
				fragColor = c;
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				if (iFrame < 60) 
				{
					fragColor = float4(.5,.5,0.,0.);
					return;
				}
				float2 odRes = 1./iResolution.xy;       
				float4 cLeft = tex2D(_BufferC, frac(uv-float2(odRes.x,0.)))*2.-1.,
				cRight = tex2D(_BufferC, frac(uv+float2(odRes.x,0.)))*2.-1.,
				cUp = tex2D(_BufferC, frac(uv-float2(0.,odRes.y)))*2.-1.,
				cDown = tex2D(_BufferC, frac(uv+float2(0.,odRes.y)))*2.-1.,
				cTopLeft = tex2D(_BufferC, frac(uv+float2(-odRes.x,-odRes.y)))*2.-1.,
				cTopRight = tex2D(_BufferC, frac(uv+float2(odRes.x,-odRes.y)))*2.-1.,
				cBottomLeft = tex2D(_BufferC, frac(uv+float2(-odRes.x,odRes.y)))*2.-1.,
				cBottomRight = tex2D(_BufferC, frac(uv+float2(odRes.x,odRes.y)))*2.-1.;   
				float4 c = float4(0,0,0,0);
				for (float x = -1.; x < 2.; x++) 
				{
					for (float y = -1.; y < 2.; y++) 
					{
						float2 v = float2(x,y);
						if (length(v) == 0.) continue;           
						c.xy -= length(tex2Dlod(_BufferA, float4(uv+odRes*v,0,0)).xy*2.-1.)*normalize(v);
					}
				}
				c.xy /= 3.*3.-1.;  
				c += cLeft*(1.+dot(float2(1.,0.),cLeft.xy));
				c += cRight*(1.+dot(float2(-1.,0.),cRight.xy));
				c += cUp*(1.+dot(float2(0.,1.),cUp.xy));
				c += cDown*(1.+dot(float2(0.,-1.),cDown.xy));
				c += cTopLeft*(1.+dot(normalize(float2(1.,1.)),cTopLeft.xy));
				c += cTopRight*(1.+dot(normalize(float2(-1.,1.)),cTopRight.xy));
				c += cBottomLeft*(1.+dot(normalize(float2(1.,-1.)),cBottomLeft.xy));
				c += cBottomRight*(1.+dot(normalize(float2(-1.,-1.)),cBottomRight.xy));
				c /= 8.5;
				c.xy = clamp(c.xy, -1., 1.);
				c = c*.5+.5;   
				fragColor = c;
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				fragColor = pow(cos(float4(length(tex2D(_BufferA,uv).xy*2.-1.),
					length(tex2D(_BufferB,uv).xy*2.-1.),
					length(tex2D(_BufferC,uv).xy*2.-1.), 1.)*32.)*0.5+0.5, float4(2.2,2.2,2.2,2.2));
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}