Shader "Hidden/TerrainShader-Base" 
{
	Properties 
	{
		_MainTex ("Base (RGB) Smoothness (A)", 2D) = "white" {}
		_MetallicTex ("Metallic (R)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
	}
	SubShader 
	{
		Tags 
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry-100"
		}
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0
		#pragma exclude_renderers gles
		#include "UnityPBSLighting.cginc"

		sampler2D _MainTex;
		sampler2D _MetallicTex;

		struct Input 
		{
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = 1;
			o.Smoothness = c.a;
			o.Metallic = tex2D (_MetallicTex, IN.uv_MainTex).r;
		}

		ENDCG
	}
	FallBack "Diffuse"
}
