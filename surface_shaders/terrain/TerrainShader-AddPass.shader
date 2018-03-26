Shader "Hidden/TerrainShader-AddPass" 
{
	Properties 
	{
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}
		[HideInInspector] [Gamma] _Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0
		[HideInInspector] _Smoothness0 ("Smoothness 0", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness1 ("Smoothness 1", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness2 ("Smoothness 2", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness3 ("Smoothness 3", Range(0.0, 1.0)) = 1.0
	}

	SubShader 
	{
		Tags 
		{
			"Queue" = "Geometry-99"
			"IgnoreProjector"="True"
			"RenderType" = "Opaque"
		}

		CGPROGRAM
		#pragma surface surface_shader Standard decal:add vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer fullforwardshadows noinstancing
		#pragma multi_compile_fog
		#pragma target 3.0
		#pragma exclude_renderers gles psp2
		#include "UnityPBSLighting.cginc"
		#pragma multi_compile __ _TERRAIN_NORMAL_MAP
		#define TERRAIN_SPLAT_ADDPASS

		half _Metallic0;
		half _Metallic1;
		half _Metallic2;
		half _Metallic3;
		half _Smoothness0;
		half _Smoothness1;
		half _Smoothness2;
		half _Smoothness3;

		struct Input
		{
			float2 uv_Splat0 : TEXCOORD0;
			float2 uv_Splat1 : TEXCOORD1;
			float2 uv_Splat2 : TEXCOORD2;
			float2 uv_Splat3 : TEXCOORD3;
			float2 tc_Control : TEXCOORD4;
			UNITY_FOG_COORDS(5)
		};

		sampler2D _Control;
		float4 _Control_ST;
		sampler2D _Splat0,_Splat1,_Splat2,_Splat3;

		#ifdef _TERRAIN_NORMAL_MAP
			sampler2D _Normal0, _Normal1, _Normal2, _Normal3;
		#endif

		void SplatmapVert(inout appdata_full v, out Input data)
		{
			UNITY_INITIALIZE_OUTPUT(Input, data);
			data.tc_Control = TRANSFORM_TEX(v.texcoord, _Control); 
			float4 pos = UnityObjectToClipPos(v.vertex);
			UNITY_TRANSFER_FOG(data, pos);
			#ifdef _TERRAIN_NORMAL_MAP
				v.tangent.xyz = cross(v.normal, float3(0,0,1));
				v.tangent.w = -1;
			#endif
		}

		void SplatmapMix(Input IN, half4 defaultAlpha, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
		{
			splat_control = tex2D(_Control, IN.tc_Control);
			weight = dot(splat_control, half4(1,1,1,1));
			#if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
				clip(weight == 0.0f ? -1 : 1);
			#endif
			splat_control /= (weight + 1e-3f);
			mixedDiffuse = 0.0f; 
			mixedDiffuse += splat_control.r * tex2D(_Splat0, IN.uv_Splat0) * half4(1.0, 1.0, 1.0, defaultAlpha.r);
			mixedDiffuse += splat_control.g * tex2D(_Splat1, IN.uv_Splat1) * half4(1.0, 1.0, 1.0, defaultAlpha.g);
			mixedDiffuse += splat_control.b * tex2D(_Splat2, IN.uv_Splat2) * half4(1.0, 1.0, 1.0, defaultAlpha.b);
			mixedDiffuse += splat_control.a * tex2D(_Splat3, IN.uv_Splat3) * half4(1.0, 1.0, 1.0, defaultAlpha.a);
			#ifdef _TERRAIN_NORMAL_MAP
				fixed4 nrm = 0.0f;
				nrm += splat_control.r * tex2D(_Normal0, IN.uv_Splat0);
				nrm += splat_control.g * tex2D(_Normal1, IN.uv_Splat1);
				nrm += splat_control.b * tex2D(_Normal2, IN.uv_Splat2);
				nrm += splat_control.a * tex2D(_Normal3, IN.uv_Splat3);
				mixedNormal = UnpackNormal(nrm);
			#endif
		}

		#ifndef TERRAIN_SURFACE_OUTPUT
			#define TERRAIN_SURFACE_OUTPUT SurfaceOutput
		#endif

		void SplatmapFinalColor(Input IN, SurfaceOutputStandard o, inout fixed4 color)
		{
			color *= o.Alpha;
			#ifdef TERRAIN_SPLAT_ADDPASS
				UNITY_APPLY_FOG_COLOR(IN.fogCoord, color, fixed4(0,0,0,0));
			#else
				UNITY_APPLY_FOG(IN.fogCoord, color);
			#endif
		}

		void SplatmapFinalPrepass(Input IN, SurfaceOutputStandard o, inout fixed4 normalSpec)
		{
			normalSpec *= o.Alpha;
		}

		void SplatmapFinalGBuffer(Input IN, SurfaceOutputStandard o, inout half4 outGBuffer0, inout half4 outGBuffer1, inout half4 outGBuffer2, inout half4 emission)
		{
			UnityStandardDataApplyWeightToGbuffer(outGBuffer0, outGBuffer1, outGBuffer2, o.Alpha);
			emission *= o.Alpha;
		}
		
		void surface_shader (Input IN, inout SurfaceOutputStandard o) 
		{
			half4 splat_control;
			half weight;
			fixed4 mixedDiffuse;
			half4 defaultSmoothness = half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);
			SplatmapMix(IN, defaultSmoothness, splat_control, weight, mixedDiffuse, o.Normal);
			o.Albedo = mixedDiffuse.rgb;
			o.Alpha = weight;
			o.Smoothness = mixedDiffuse.a;
			o.Metallic = dot(splat_control, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));
		}
		ENDCG
	}
	Fallback "Hidden/TerrainEngine/Splatmap/Diffuse-AddPass"
}
