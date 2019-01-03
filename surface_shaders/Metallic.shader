Shader "Metallic"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo Map", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_MetallicGlossMap ("Metallic (R) Smoothness(A) Map", 2D) = "black" {}
	}

	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow

		sampler2D _MainTex, _BumpMap, _MetallicGlossMap;
		float4 _Color;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_MetallicGlossMap;
		};

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = tex2D(_MainTex,IN.uv_MainTex) * _Color ; 
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap)); 
			o.Metallic = tex2D(_MetallicGlossMap, IN.uv_MetallicGlossMap).r; 
			o.Smoothness = tex2D(_MetallicGlossMap, IN.uv_MetallicGlossMap).a; 
		}

		ENDCG
	}
}