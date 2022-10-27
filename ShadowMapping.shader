Shader "ShadowMapping"
{
	Properties
	{
		[HideInInspector] _MainTex ("Texture", 2D) = "black" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float4x4 _ProjectionToWorld, _LightViewProjection;
			sampler2D _CameraDepthTexture, _LastCameraDepthTexture, _MainTex;
			float _ShadowBias, _InvertY;

			float4 VSMain (in float4 vertex : POSITION, inout float2 uv : TEXCOORD0, out float3 direction : TEXCOORD1) : SV_POSITION
			{
				float4 position = UnityObjectToClipPos(vertex);
				direction = mul(_ProjectionToWorld, float4(position.xy, 0.0, 1.0)) - _WorldSpaceCameraPos;
				return position;
			}

			void PSMain (float4 vertex : SV_POSITION, float2 uv : TEXCOORD0, float3 direction : TEXCOORD1, out float4 fragColor : SV_TARGET)
			{
				float sceneDepth = 1.0 / (_ZBufferParams.z * tex2D(_CameraDepthTexture, uv.xy) + _ZBufferParams.w);
				float3 worldSpace = direction * sceneDepth + _WorldSpaceCameraPos;
				float4 shadowCoord = mul(_LightViewProjection, float4(worldSpace, 1.0));
				float2 projCoords = (shadowCoord.xy / shadowCoord.w) * 0.5 + 0.5;
				float depth = (shadowCoord.z / shadowCoord.w);
				if (_InvertY > 0.5f) projCoords.y = 1.0 - projCoords.y;
				float closestDepth = 1.0 / (_ZBufferParams.z * tex2D(_LastCameraDepthTexture, projCoords.xy).r + _ZBufferParams.w);
				float currentDepth = 1.0 / (_ZBufferParams.z * depth + _ZBufferParams.w);
				float shadow = ((currentDepth - _ShadowBias) < closestDepth) || (depth > 0.5) ? 0.0 : 1.0;
				float4 color = float4(1.0 - shadow.xxx, 1.0);
				bool isLightFrustum = depth > 0.0;
				isLightFrustum = isLightFrustum && projCoords.x >= 0.0 && projCoords.x <= 1.0;
				isLightFrustum = isLightFrustum && projCoords.y >= 0.0 && projCoords.y <= 1.0;
				isLightFrustum = isLightFrustum && sceneDepth <= (_ProjectionParams.z - _ProjectionParams.y);
				float4 baseColor = tex2D(_MainTex, uv);
				fragColor = isLightFrustum ? ((color.r > 0.5) ? baseColor * float4(1,1,1,1) : baseColor * float4(0,0,0,1)) : baseColor;
			}
			ENDCG
		}
	}
}