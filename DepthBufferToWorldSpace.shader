Shader "DepthBufferToWorldSpace"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float4x4 unity_ProjectionToWorld;
			sampler2D _CameraDepthTexture;

			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0, out float3 direction:TEXCOORD1)
			{
				vertex = UnityObjectToClipPos(vertex);
				direction = mul(unity_ProjectionToWorld, float4(vertex.xy, 0.0, 1.0)) - _WorldSpaceCameraPos;
			}

			void PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, float3 direction:TEXCOORD1, out float4 fragColor:SV_TARGET)
			{
				float depth = 1.0 / (_ZBufferParams.z * tex2D(_CameraDepthTexture, uv.xy) + _ZBufferParams.w);
				float3 worldspace = direction * depth + _WorldSpaceCameraPos;
				fragColor = float4(worldspace, 1.0);
			}

			ENDCG
		}
	}
}