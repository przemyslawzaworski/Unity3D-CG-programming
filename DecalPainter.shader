Shader "DecalPainter"
{
	SubShader
	{
		Pass
		{
			ZTest Off
			ZWrite Off
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			float4x4 _MeshModelMatrix, _DecalViewMatrix, _DecalProjectionMatrix;
			sampler2D _DecalTexture;

			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0, out float4 worldPos:TEXCOORD1, out float4 clipPos:TEXCOORD2)
			{
				worldPos = mul(_MeshModelMatrix, vertex);
				clipPos = mul(_DecalViewMatrix, worldPos);
				clipPos = mul(_DecalProjectionMatrix, clipPos);	
				float2 texcoord = uv.xy;
				texcoord.y = 1.0 - texcoord.y; 
				texcoord = texcoord * 2.0 - 1.0;
				vertex = float4(texcoord, 0.0, 1.0);
			}

			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, float4 worldPos:TEXCOORD1, float4 clipPos:TEXCOORD2) : SV_TARGET
			{
				float2 tc = float2( clipPos.x / clipPos.w, clipPos.y / clipPos.w) / 2.0 + 0.5;
				return (tc.x > 0.0 && tc.x < 1.0 && tc.y > 0.0 && tc.y < 1.0) ? tex2D(_DecalTexture, tc) : float4(1, 0, 0, 1);
			}
			ENDCG
		}
	}
}