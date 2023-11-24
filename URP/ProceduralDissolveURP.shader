Shader "Procedural Dissolve URP"
{
	Properties 
	{
		[Header(Offsets used to modify UV.x)]
		_OffsetX ("Offset X", Float) = 0.0
		[Header(Offsets used to modify UV.y)]
		_OffsetY ("Offset Y", Float) = 0.0
		[Header(Layers of noise)]
		_Octaves ("Octaves", Int) = 5
		[Header(Initial strength or amplitude of the noise)]
		_Amplitude("Amplitude", Range(0.0, 5.0)) = 1.5
		[Header(Amplitude is multiplied for each octave)]
		_Gain("Gain", Range(0.0, 1.0)) = 0.5
		[Header(Initial frequency of the noise)]
		_Frequency("Frequency", Range(0.0, 6.0)) = 2.0
		[Header(Frequency is multiplied for each octave)]
		_Lacunarity("Lacunarity", Range(1.0, 5.0)) = 2
		[Header(Accumulated noise value)]
		_Value("Value", Range(-2.0, 2.0)) = 0.0
		[Header(Exp factor used to adjust the final value)]
		_Power("Power", Range(0.1, 5.0)) = 1.0
		[Header(Scale factor applied to the UV)]
		_Scale("Scale", Float) = 1.0
		[Header(Color)]
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[Header(Enable Dissolve)]
		[Toggle] _Monochromatic("Monochromatic", Float) = 1
		[Header(Dissolve Factor)]
		_Range("Monochromatic Range", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _Cull("__cull", Float) = 2.0
	}
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
		float4 _Color;
		float _OffsetX, _OffsetY, _Octaves, _Lacunarity, _Gain, _Value, _Amplitude, _Frequency;  
		float _Power, _Scale, _Monochromatic, _Range;	
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

			float FBM(float2 p, float ox, float oy, int octaves, float lacunarity, float gain, float value, 
			          float amplitude, float frequency, float power, float scale)
			{
				p = p * scale + float2(ox, oy);
				for(int i = 0; i < octaves; i++)
				{
					float2 i = floor(p * frequency);
					float2 f = frac(p * frequency);
					float2 t = f * f * f * ( f * ( f * 6.0 - 15.0 ) + 10.0 ); 
					float2 a = i + float2( 0.0, 0.0 );
					float2 b = i + float2( 1.0, 0.0 );
					float2 c = i + float2( 0.0, 1.0 );
					float2 d = i + float2( 1.0, 1.0 );
					a = -1.0 + 2.0 * frac(sin(float2(dot(a, float2(127.1, 311.7)), dot(a, float2(269.5,183.3)))) * 43758.5453123);
					b = -1.0 + 2.0 * frac(sin(float2(dot(b, float2(127.1, 311.7)), dot(b, float2(269.5,183.3)))) * 43758.5453123);
					c = -1.0 + 2.0 * frac(sin(float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5,183.3)))) * 43758.5453123);
					d = -1.0 + 2.0 * frac(sin(float2(dot(d, float2(127.1, 311.7)), dot(d, float2(269.5,183.3)))) * 43758.5453123);
					float A = dot(a, f - float2( 0.0, 0.0 ));
					float B = dot(b, f - float2( 1.0, 0.0 ));
					float C = dot(c, f - float2( 0.0, 1.0 ));
					float D = dot(d, f - float2( 1.0, 1.0 ));
					float noise = lerp( lerp( A, B, t.x ), lerp( C, D, t.x ), t.y);
					value += amplitude * noise;
					frequency *= lacunarity;
					amplitude *= gain;
				} 
				value = clamp(value, -1.0, 1.0);
				return pow(value * 0.5 + 0.5, power);
			}

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
				float n = FBM(uv, _OffsetX, _OffsetY, _Octaves, _Lacunarity, _Gain, _Value, _Amplitude, _Frequency, _Power, _Scale);
				return (_Monochromatic < 0.5) ? float4(n.xxx, 1.0) * _Color : (n < _Range) ? float4(0,0,0,1) : float4(1,1,1,1);
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