Shader "FBM Generator version 1"
{
	Properties
	{
		[KeywordEnum(FBM0,FBM1,FBM2,FBM3,FBM4,FBM5,FBM6)] DOMAIN1("First domain function", Int) = 6
		[KeywordEnum(FBM0,FBM1,FBM2,FBM3,FBM4,FBM5,FBM6)] DOMAIN2("Second domain function", Int) = 6	
		[KeywordEnum(FBM0,FBM1,FBM2,FBM3,FBM4,FBM5,FBM6)] DOMAIN3("Third domain function", Int) = 6		
		COLORS("Base colors amount <2-4>",Int) = 2
		S("S",Range(-10.0,10.0)) = 5.0		
		AA("AA",Range(-10.0,10.0)) = 5.0
		BB("BB",Range(-10.0,10.0)) = 1.0 		
		A("A",Range(-10.0,10.0)) = -1.0
		B("B",Range(-10.0,10.0)) = 1.0  
		C("C",Range(-10.0,10.0)) = 2.0
		D("D",Range(-10.0,10.0)) = -0.5   
		E("E",Range(0.00,2.0)) = 0.28   
		F("F",Range(0.00,2.0)) = 1.04
		color1 ("Color 1", Color) = (1.0,0.1,0.1,1)	
		color2 ("Color 2", Color) = (0.2,0.2,1.0,1)	
		color3 ("Color 3", Color) = (0.3,0.3,0.3,1)		
		color4 ("Color 4", Color) = (0.3,0.3,0.3,1)			
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			int COLORS,DOMAIN1,DOMAIN2,DOMAIN3;
			float A,B,C,D,E,F,AA,BB,S;
			float4 color1,color2,color3,color4;
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
 
			static const float2x2 m = float2x2( A,B,C,D );

			float hash (float2 n) 
			{ 
				return frac(sin(dot(n, float2(95.43583, 93.323197))) * 65536.32);
			}

			float noise(float2 p)
			{
				float2 i = floor(p);
				float2 u = frac(p);
				u = u*u*(3.0-2.0*u);
				float2 d = float2 (1.0,0.0);
				float r = lerp(lerp(hash(i),hash(i+d.xy),u.x),lerp(hash(i+d.yx),hash(i+d.xx),u.x),u.y);
				return r*r;
			}

			float fbm( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p ));
				return f;
			}
			
			float fbm2( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p )); p = p*2.02; p=mul(p,m);
				f += 0.250000*(E+F*noise( p ));
				return f;
			}
			
			float fbm3( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p )); p = p*2.02; p=mul(p,m);
				f += 0.250000*(E+F*noise( p )); p = p*2.03; p=mul(p,m);
				f += 0.125000*(E+F*noise( p )); 
				return f;
			}
			
			float fbm4( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p )); p = p*2.02; p=mul(p,m);
				f += 0.250000*(E+F*noise( p )); p = p*2.03; p=mul(p,m);
				f += 0.125000*(E+F*noise( p )); p = p*2.01; p=mul(p,m);
				f += 0.062500*(E+F*noise( p ));
				return f;
			}

			float fbm5( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p )); p = p*2.02; p=mul(p,m);
				f += 0.250000*(E+F*noise( p )); p = p*2.03; p=mul(p,m);
				f += 0.125000*(E+F*noise( p )); p = p*2.01; p=mul(p,m);
				f += 0.062500*(E+F*noise( p )); p = p*2.04; p=mul(p,m);
				f += 0.031250*(E+F*noise( p )); 
				return f;
			}
			
			float fbm6( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(E+F*noise( p )); p = p*2.02; p=mul(p,m);
				f += 0.250000*(E+F*noise( p )); p = p*2.03; p=mul(p,m);
				f += 0.125000*(E+F*noise( p )); p = p*2.01; p=mul(p,m);
				f += 0.062500*(E+F*noise( p )); p = p*2.04; p=mul(p,m);
				f += 0.031250*(E+F*noise( p )); p = p*2.01; p=mul(p,m);
				f += 0.015625*(E+F*noise( p ));
				return f;
			}

			float warping( float2 p )
			{
				float d1,d2;
				if (DOMAIN1==1) d1 = fbm(p+float2(0.0,0.0));
				else
				if (DOMAIN1==2) d1 = fbm2(p+float2(0.0,0.0));
				else
				if (DOMAIN1==3) d1 = fbm3(p+float2(0.0,0.0));
				else
				if (DOMAIN1==4) d1 = fbm4(p+float2(0.0,0.0));
				else
				if (DOMAIN1==5) d1 = fbm5(p+float2(0.0,0.0));
				else
				d1 = fbm6(p);
				
				if (DOMAIN2==1) d2 = fbm(p+float2(AA,BB));
				else
				if (DOMAIN2==2) d2 = fbm2(p+float2(AA,BB));
				else
				if (DOMAIN2==3) d2 = fbm3(p+float2(AA,BB));
				else
				if (DOMAIN2==4) d2 = fbm4(p+float2(AA,BB));
				else
				if (DOMAIN2==5) d2 = fbm5(p+float2(AA,BB));
				else
				d2 = fbm6(p+float2(AA,BB));
				
				float2 q = float2(d1,d2);

				if (DOMAIN3==1) return fbm( p + S*q );
				else
				if (DOMAIN3==2) return fbm2( p + S*q );
				else
				if (DOMAIN3==3) return fbm3( p + S*q );
				else
				if (DOMAIN3==4) return fbm4( p + S*q );
				else
				if (DOMAIN3==5) return fbm5( p + S*q );
				else
				return fbm6( p + S*q );			
			}
	
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 uv = ps.uv.xy;
				float color;
				float4 temp;
				color = warping(uv);
				
				if (COLORS==2) return lerp(color1,color2,color);
				else
				if (COLORS==3) 
				{
					temp=lerp(color1,color2,color);
					return lerp(temp,color3,color);
				}
				else
				{
					temp=lerp(color1,color2,color);
					temp=lerp(temp,color3,color);
					return lerp(temp,color4,color);
				}       
			}         
			ENDCG
		}
	}
}