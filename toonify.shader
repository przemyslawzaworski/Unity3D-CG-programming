// Original reference: https://www.geeks3d.com/20140523/glsl-shader-library-toonify-post-processing-filter/

Shader "Toonify"
{
	Properties
	{
		[HideInInspector]
		_MainTex ("Texture", 2D) = "black" {}
		edge_thres ("Edge Threshold", Range (0.0,1.0)) = 0.2
		edge_thres2 ("Edge Threshold 2", Range (0.0,10.0)) = 5.0
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			
			float edge_thres, edge_thres2;
			
			#define HueLevCount 6
			#define SatLevCount 7
			#define ValLevCount 4
			
			static const float HueLevels[HueLevCount] = {0.0,140.0,160.0,240.0,240.0,360.0};
			static const float SatLevels[SatLevCount] = {0.0,0.15,0.3,0.45,0.6,0.8,1.0};
			static const float ValLevels[ValLevCount] = {0.0,0.3,0.6,1.0};

			float3 RGBtoHSV( float r, float g, float b) 
			{
				float minv, maxv, delta;
				float3 res = float3(0,0,0);
				minv = min(min(r, g), b);
				maxv = max(max(r, g), b);
				res.z = maxv; 
				delta = maxv - minv;
				
				if( maxv != 0.0 )
				{
					res.y = delta / maxv; 
				}		
				else 
				{
					res.y = 0.0;
					res.x = -1.0;
					return res;
				}

				if( r == maxv )
					res.x = ( g - b ) / delta;      
				else if( g == maxv )
					res.x = 2.0 + ( b - r ) / delta;   
				else
					res.x = 4.0 + ( r - g ) / delta;   

				res.x = res.x * 60.0;
				if( res.x < 0.0 )
					res.x = res.x + 360.0;
				  
				return res;
			}

			float3 HSVtoRGB(float h, float s, float v ) 
			{
				int i;
				float f, p, q, t;
				float3 res = float3(0,0,0);

				if( s == 0.0 ) 
				{
					res.x = v;
					res.y = v;
					res.z = v;
					return res;
				}

				h /= 60.0;      
				i = int(floor( h ));
				f = h - float(i); 
				p = v * ( 1.0 - s );
				q = v * ( 1.0 - s * f );
				t = v * ( 1.0 - s * ( 1.0 - f ) );

				switch(i) 
				{
					case 0:
						res.x = v;
						res.y = t;
						res.z = p;
						break;
					case 1:
						res.x = q;
						res.y = v;
						res.z = p;
						break;
					case 2:
						res.x = p;
						res.y = v;
						res.z = t;
						break;
					case 3:
						res.x = p;
						res.y = q;
						res.z = v;
						break;
					case 4:
						res.x = t;
						res.y = p;
						res.z = v;
						break;
					default:      
						res.x = v;
						res.y = p;
						res.z = q;
						break;
				}
				
				return res;
			}

			float nearestLevel(float col, int mode) 
			{
				int levCount;
				if (mode==0) levCount = HueLevCount;
				if (mode==1) levCount = SatLevCount;
				if (mode==2) levCount = ValLevCount;
			   
				for (int i = 0; i<levCount-1; i++ ) 
				{
					if (mode==0) 
					{
						if (col >= HueLevels[i] && col <= HueLevels[i+1]) 
						{
							return HueLevels[i+1];
						}
					}
					if (mode==1) 
					{
						if (col >= SatLevels[i] && col <= SatLevels[i+1]) 
						{
							return SatLevels[i+1];
						}
					}
					if (mode==2) 
					{
						if (col >= ValLevels[i] && col <= ValLevels[i+1]) 
						{
							return ValLevels[i+1];
						}
					}
				}
				
				return 0.0;
			}

			float avg_intensity(float4 pix) 
			{
				return (pix.r + pix.g + pix.b)/3.0;
			}

			float4 get_pixel(float2 coords, float dx, float dy) 
			{
				return tex2D(_MainTex,coords + float2(dx, dy));
			}

			float IsEdge(in float2 coords)
			{
				float dxtex = _MainTex_TexelSize.x ;
				float dytex = _MainTex_TexelSize.y;
				float pix[9];
				int k = -1;
				float delta;
				for (int i=-1; i<2; i++) 
				{
					for(int j=-1; j<2; j++) 
					{
						k++;
						pix[k] = avg_intensity(get_pixel(coords,float(i)*dxtex, float(j)*dytex));
					}
				}
				delta = (abs(pix[1]-pix[7]) + abs(pix[5]-pix[3]) + abs(pix[0]-pix[8]) + abs(pix[2]-pix[6]))/4.;
				return clamp(edge_thres2*delta,0.0,1.0);
			}
			
			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_TARGET
			{
				float4 tc = float4(1.0, 0.0, 0.0, 1.0);
				uv = vertex.xy/_ScreenParams.xy;
				#if UNITY_UV_STARTS_AT_TOP
					uv.y = 1.0 - uv.y;
				#endif
				float3 colorOrg = tex2D(_MainTex, uv).rgb;
				float3 vHSV =  RGBtoHSV(colorOrg.r,colorOrg.g,colorOrg.b);
				vHSV.x = nearestLevel(vHSV.x, 0);
				vHSV.y = nearestLevel(vHSV.y, 1);
				vHSV.z = nearestLevel(vHSV.z, 2);
				float edg = IsEdge(uv);
				float3 vRGB = (edg >= edge_thres)? float3(0.0,0.0,0.0):HSVtoRGB(vHSV.x,vHSV.y,vHSV.z);
				return float4(vRGB.x,vRGB.y,vRGB.z, 1); 
			}
			ENDCG
		}
	}
}