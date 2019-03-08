// Original reference: https://www.shadertoy.com/view/4sKBz3
// Converted by Przemyslaw Zaworski

Shader "WindFlowMap"
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
		float4 iResolution;

		#define PI 3.14159265359
		#define ITERATIONS 4
		#define HASHSCALE1 .1031
		#define HASHSCALE3 float3(.1031, .1030, .0973)
		#define HASHSCALE4 float4(.1031, .1030, .0973, .1099)

		float hash13(float3 p3)
		{
			p3  = frac(p3 * HASHSCALE1);
			p3 += dot(p3, p3.yzx + 19.19);
			return frac((p3.x + p3.y) * p3.z);
		}

		float2 hash21(float p)
		{
			float3 p3 = frac(float3(p,p,p) * HASHSCALE3);
			p3 += dot(p3, p3.yzx + 19.19);
			return frac((p3.xx+p3.yz)*p3.zy);
		}

		float3 BilinearTextureSample (sampler2D image, float2 P)
		{
			float textureSize = 256.0;
			float s = (1.0 / textureSize);
			float2 pixel = P * textureSize + 0.5;   
			float2 f = frac(pixel);
			pixel = (floor(pixel) / textureSize) - float2(s/2.0, s/2.0);
			float3 C11 = tex2D(image, pixel + float2( 0.0, 0.0)).rgb;
			float3 C21 = tex2D(image, pixel + float2( s, 0.0)).rgb;
			float3 C12 = tex2D(image, pixel + float2( 0.0, s)).rgb;
			float3 C22 = tex2D(image, pixel + float2( s, s)).rgb;
			float3 x1 = lerp(C11, C21, f.x);
			float3 x2 = lerp(C12, C22, f.x);
			return lerp(x1, x2, f.y);
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
			
			float4 hash(float2 x)
			{
				x = floor(256.0 * x) / 256.0;
				uint2 p = asuint(x);
				p = 1103515245U*((p >> 1U)^(p.yx));
				uint h32 = 1103515245U*((p.x)^(p.y>>3U));
				uint n = h32^(h32 >> 16);    
				uint4 rz = uint4(n, n*16807U, n*48271U, n*69621U);
				return float4(rz & uint4(0x7fffffffU.xxxx))/float(0x7fffffff);
			}
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				fragColor = hash(uv);
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------
		
		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{			
				float2 fragCoord = uv * iResolution.xy;
				fragColor = 0..xxxx;
				float2 p = tex2D(_BufferB, uv).xy;
				if(p.x == 0 && p.y == 0) 
				{
					if (hash13(float3(fragCoord, iFrame)) > 2e-4) return;
					p = fragCoord + hash21(float(iFrame)) - 0.5;
				}
				float2 v = 2. * BilinearTextureSample(_BufferD, 0.03*uv).xy - 1.;
				fragColor.xy = p + v;
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
	
		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;
				fragColor = 0..xxxx;
				for(int i = -1; i <= 1; i++) 
				{
					for(int j = -1; j <= 1; j++) 
					{
						float4 c = tex2Dlod(_BufferA, float4((fragCoord + float2(i,j)) / iResolution.xy, 0, 0));
						if(abs(c.x - fragCoord.x) < 0.5 && abs(c.y - fragCoord.y) < 0.5) 
						{
							fragColor = c;
							return;
						}
					}
				}
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 v = 2. * BilinearTextureSample(_BufferD, 0.03*uv).xy - 1.;
				float r = 0.96 * tex2D(_BufferC, uv).x;
				if (tex2D(_BufferB, uv).x > 0.) r = 1.;
				fragColor.x = r;
			}
			
			ENDCG
		}
		
//-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float r = tex2D(_BufferC, uv).x;
				r = 0.9 - 0.8 * r;
				fragColor = float4(r.xxx, 1);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}