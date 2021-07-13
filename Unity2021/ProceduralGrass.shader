Shader "ProceduralGrass"
{
	Properties
	{
		_MainTex ("MainTex ", 2D) = "white" {}
	}
	Subshader
	{
		Cull Off
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow
		#pragma target 5.0

		sampler2D _MainTex;

		struct Input 
		{
			float2 uv_MainTex;
		};

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			float4 color = tex2D(_MainTex, IN.uv_MainTex);
			if (color.a < 0.5) discard;
			o.Albedo = color;
		}

		ENDCG
	}
}