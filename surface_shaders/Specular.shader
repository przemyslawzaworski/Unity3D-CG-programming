Shader "Specular"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo Map", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_SpecGlossMap ("Specular (RGB) Smoothness(A) Map", 2D) = "black" {}
	}

	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface SurfaceShader StandardSpecular fullforwardshadows addshadow

		sampler2D _MainTex, _BumpMap, _SpecGlossMap;
		float4 _Color;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_SpecGlossMap;
		};

		void SurfaceShader (Input IN, inout SurfaceOutputStandardSpecular o) 
		{
			o.Albedo = tex2D(_MainTex,IN.uv_MainTex) * _Color ; 
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap)); 
			o.Specular = tex2D(_SpecGlossMap, IN.uv_SpecGlossMap).rgb; 
			o.Smoothness = tex2D(_SpecGlossMap, IN.uv_SpecGlossMap).a; 
		}

		ENDCG
	}
}