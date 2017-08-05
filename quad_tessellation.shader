//Enable option "Keep quads" in model import settings.
//source: https://forum.unity3d.com/threads/my-own-terrane-shader-is-not-working.283406/
Shader "Quad tessellation" 
{
	SubShader 
	{
		Pass 
		{ 
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma hull hull_shader
			#pragma domain domain_shader
			#pragma fragment pixel_shader
 
			struct VS_OUTPUT
			{
				float4 position : POSITION;
			};
 
			struct HS_CONSTANT_DATA_OUTPUT
			{
				float Edges[4] : SV_TessFactor;
				float Inside[2] : SV_InsideTessFactor;
			};
 
			struct HS_OUTPUT
			{
				float3 position : POS;
			};
 
			float4 vertex_shader(float4 vertex:POSITION):POSITION
			{
				return mul(UNITY_MATRIX_MV, vertex);
			}
 
			HS_CONSTANT_DATA_OUTPUT constantsHS(InputPatch<VS_OUTPUT, 4> patch)
			{
				HS_CONSTANT_DATA_OUTPUT output;
				output.Edges[0] = output.Edges[1] = output.Edges[2] = output.Edges[3] = 2;
				output.Inside[0] = output.Inside[1] = 2;  
				return output;
			}
 
			[domain("quad")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[outputcontrolpoints(4)]
			[patchconstantfunc("constantsHS")]
			
			HS_OUTPUT hull_shader(InputPatch<VS_OUTPUT, 4>patch, uint id: SV_OutputControlPointID)
			{
				HS_OUTPUT output;
				output.position = patch[id].position.xyz;			   
				return output;
			}
 
			[domain("quad")]
			float4 domain_shader(HS_CONSTANT_DATA_OUTPUT input, const OutputPatch<HS_OUTPUT, 4>patch,float2 UV:SV_DomainLocation):SV_POSITION
			{
				float3 a = lerp(patch[0].position, patch[1].position, UV.x);
				float3 b = lerp(patch[3].position, patch[2].position, UV.x);
				float3 pos = lerp(a,b,UV.y);                       
				return mul(UNITY_MATRIX_P, float4(pos, 1.0));
			}

			float4 pixel_shader(float4 color:SV_POSITION) : SV_TARGET
			{  
				return float4(1.0,0.0,0.0,1.0);
			}
 
			ENDCG
		}
	}
}