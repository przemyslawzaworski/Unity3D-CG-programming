// Test DirectX 12 Shader Model 6.6 Pack/Unpack Math Intrinsics
// https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_Pack_Unpack_Intrinsics.html
// Required Windows 11 and Unity 2023.2+
Shader "Cobalt"
{
	SubShader
	{
		Pass
		{
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#include "UnityCG.cginc"
			#pragma require Int64BufferAtomics
			#pragma require Native16Bit

			float4 VSMain(float3 position : POSITION) : SV_Position
			{
				return UnityObjectToClipPos(position);
			}

			float4 PSMain(float4 p : SV_POSITION) : SV_Target
			{
				uint16_t4 cobalt = uint16_t4(0, 32, 194, 255);
				uint8_t4_packed encode = pack_u8(cobalt);
				uint16_t4 decode = unpack_u8u16(encode);
				return (float4)(decode / 255.0);
			}
			ENDHLSL
		}
	}
}