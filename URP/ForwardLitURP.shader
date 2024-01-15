Shader "Forward Lit URP"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_BaseMap("BaseMap", 2D) = "black" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
		[HideInInspector] _QueueControl("_QueueControl", Float) = -1
		[HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
		[HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
		[HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Lit" }
		Cull Back
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
		ENDHLSL

		Pass
		{
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#define _NORMAL_DROPOFF_TS 1
			#define _NORMALMAP 1
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
			#define SHADERPASS SHADERPASS_FORWARD
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#if defined(LOD_FADE_CROSSFADE)
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _NormalMap_ST;
			CBUFFER_END

			sampler2D _BaseMap;
			sampler2D _NormalMap;
			float _Metallic, _Smoothness;
			
			VertexOutput VSMain( VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.texcoord8.xy = v.texcoord.xy;
				o.texcoord8.zw = 0;
				v.normalOS = v.normalOS;
				v.tangentOS = v.tangentOS;
				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( v.normalOS, v.tangentOS );
				o.tSpace0 = float4( normalInput.normalWS, vertexInput.positionWS.x );
				o.tSpace1 = float4( normalInput.tangentWS, vertexInput.positionWS.y );
				o.tSpace2 = float4( normalInput.bitangentWS, vertexInput.positionWS.z );
				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif
				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				half3 vertexLight = VertexLighting( vertexInput.positionWS, normalInput.normalWS );
				#ifdef FOG
					half fogFactor = ComputeFogFactor( vertexInput.positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			half4 PSMain ( VertexOutput IN
						#ifdef DEPTH_WRITE_ON
						,out float outputDepth : SV_Depth
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				float3 WorldNormal = normalize( IN.tSpace0.xyz );
				float3 WorldTangent = IN.tSpace1.xyz;
				float3 WorldBiTangent = IN.tSpace2.xyz;
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );
				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionCS);
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
				WorldViewDirection = SafeNormalize( WorldViewDirection );
				float2 uv_BaseMap = IN.texcoord8.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float2 uv_NormalMap = IN.texcoord8.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float3 BaseColor = tex2D( _BaseMap, uv_BaseMap ).rgb;
				float3 Normal = UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f );
				float3 Emission = 0;
				float3 Specular = 0.0;
				float Metallic = _Metallic;
				float Smoothness = _Smoothness;
				float Occlusion = 1;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				#ifdef DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif
				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif
				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif
				#ifdef FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif
				#ifdef _BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);
				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif
				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;
				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.positionCS, surfaceData, inputData);
				#endif
				half4 color = UniversalFragmentPBR( inputData, surfaceData);
				#ifdef _FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif
				#ifdef FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				#ifdef DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
				return color;
			}
			ENDHLSL
		}
	
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }
			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _NORMALMAP 1
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
			#define SHADERPASS SHADERPASS_SHADOWCASTER
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#if defined(LOD_FADE_CROSSFADE)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD2;
				#endif
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _NormalMap_ST;
			CBUFFER_END

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VSMain( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				v.normalOS = v.normalOS;
				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif
				float3 normalWS = TransformObjectToWorldDir(v.normalOS);
				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.positionCS = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			half4 PSMain(VertexOutput IN
						#ifdef DEPTH_WRITE_ON
						,out float outputDepth : SV_Depth
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );
				#if defined(_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				#ifdef DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif
				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif
				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				#ifdef DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				return 0;
			}
			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }
			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _NORMALMAP 1
			#pragma vertex VSMain
			#pragma fragment PSMain
			#define SHADERPASS SHADERPASS_DEPTHONLY
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#if defined(LOD_FADE_CROSSFADE)
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD2;
				#endif
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _NormalMap_ST;
			CBUFFER_END
	
			VertexOutput VSMain( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				v.normalOS = v.normalOS;
				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = vertexInput.positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			half4 PSMain(VertexOutput IN
						#ifdef DEPTH_WRITE_ON
						,out float outputDepth : SV_Depth
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );
				#if defined(_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				#ifdef DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif
				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif
				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				#ifdef DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				return 0;
			}
			ENDHLSL
		}

		Pass
		{
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }
			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#define _NORMALMAP 1
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#if defined(LOD_FADE_CROSSFADE)
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
			#endif

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD3;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD4;
				#endif
				float4 texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _BaseMap_ST;
			float4 _NormalMap_ST;
			CBUFFER_END

			sampler2D _NormalMap;

			VertexOutput VSMain( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.texcoord5.xy = v.texcoord.xy;
				o.texcoord5.zw = 0;
				v.normalOS = v.normalOS;
				v.tangentOS = v.tangentOS;
				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal( v.normalOS );
				float4 tangentWS = float4( TransformObjectToWorldDir( v.tangentOS.xyz ), v.tangentOS.w );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = vertexInput.positionWS;
				#endif
				o.worldNormal = normalWS;
				o.worldTangent = tangentWS;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(_NEEDS_FRAG_SHADOWCOORDS)
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.positionCS = vertexInput.positionCS;
				o.clipPosV = vertexInput.positionCS;
				return o;
			}

			void PSMain(VertexOutput IN
						, out half4 outNormalWS : SV_Target0
						#ifdef DEPTH_WRITE_ON
						,out float outputDepth : SV_Depth
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				#if defined(_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );
				#if defined(_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 uv_NormalMap = IN.texcoord5.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float3 Normal = UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f );
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				#ifdef DEPTH_WRITE_ON
					float DepthValue = IN.positionCS.z;
				#endif
				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif
				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				#ifdef DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif
				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
			}
			ENDHLSL
		}
	}
	Fallback Off
}