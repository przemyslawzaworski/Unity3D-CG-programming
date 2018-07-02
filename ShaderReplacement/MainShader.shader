Shader "ShaderReplacement/MainShader"
{
	Properties
	{
		[Header(Texture Maps)]
		_MainTex ("Albedo Map", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "black" {}
		_SpecGlossMap ("Specular (RGB) Smoothness(A) Map", 2D) = "gray" {}
	}
	Subshader
	{
		Tags {"RenderType" = "CustomRendering"}	
		CGPROGRAM
		#pragma surface SurfaceShader  StandardSpecular  fullforwardshadows addshadow

		sampler2D _MainTex,_BumpMap,_SpecGlossMap;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_SpecGlossMap; 			
		};

		void SurfaceShader (Input IN, inout SurfaceOutputStandardSpecular o) 
		{
				o.Albedo = tex2D(_MainTex,IN.uv_MainTex) ; 
				o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap)); 
				o.Specular = tex2D(_SpecGlossMap, IN.uv_SpecGlossMap).rgb; 
				o.Smoothness = tex2D(_SpecGlossMap, IN.uv_SpecGlossMap).a; 
		}
		ENDCG	
	}
}