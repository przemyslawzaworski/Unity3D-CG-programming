Shader "Paint URP Unlit"
{
	SubShader 
	{
		Tags 
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
			"UniversalMaterialType" = "Lit" 
			"IgnoreProjector" = "True"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		float _Cutoff;
		CBUFFER_END
		ENDHLSL

		Pass 
		{
			Name "Unlit"

			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma shader_feature _ALPHATEST_ON

			struct Attributes 
			{
				float4 vertex	: POSITION;
				float2 uv		: TEXCOORD0;
				float4 color	: COLOR;
			};

			struct Varyings 
			{
				float4 vertex 	: SV_POSITION;
				float2 uv		: TEXCOORD0;
				float4 color	: COLOR;
			};

			TEXTURE2D(_PaintMap);
			SAMPLER(sampler_PaintMap);

			TEXTURE2D(_ColorMap);
			SAMPLER(sampler_ColorMap);

			Varyings VSMain(Attributes IN) 
			{
				Varyings OUT;
				OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}

			float4 PSMain(Varyings IN) : SV_Target 
			{
				float2 uv = IN.uv.xy;
				float3 color = _ColorMap.Sample(sampler_ColorMap, uv).rgb;
				float paint = _PaintMap.Sample(sampler_PaintMap, uv).r;
				return float4(lerp(float3(0,0,0), color, paint), 1.0);
			}
			ENDHLSL
		}

		Pass 
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }
			ZWrite On
			ZTest LEqual
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma multi_compile_instancing
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
			ENDHLSL
		}

		Pass 
		{
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }
			ColorMask 0
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma multi_compile_instancing
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
			ENDHLSL
		}

		Pass 
		{
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma multi_compile_instancing
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
			ENDHLSL
		}
	}
}