// 256 x 256 RGBA procedural noise texture with bilinear filtering
// References:
// https://www.shadertoy.com/view/Xt3cDn
// https://www.shadertoy.com/view/MllSzX

Shader "NoiseTexture"
{
	SubShader
	{

//-------------------------------------------------------------------------------------------
	
		CGINCLUDE
		#pragma vertex SetVertexShader
		#pragma fragment SetPixelShader
		
		sampler2D _BufferA;	
		
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
				//x = fmod( floor(256.0*x), 256.0 ); <- repeat pattern
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
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				fragColor = float4(BilinearTextureSample(_BufferA,uv),1.0);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}