Shader "Vface"
{
	SubShader
	{
		Cull Off
		CGPROGRAM
		#pragma target 5.0
		#pragma surface SurfaceShader Standard 
		
		struct Input { float IsFacing:VFACE; };

		void SurfaceShader( Input i , inout SurfaceOutputStandard o )
		{
			float4 color = (i.IsFacing>0) ? float4(1,0,0,1) : float4(0,0,1,1);
			o.Emission = color.rgb;
			o.Alpha = color.a;
		}

		ENDCG
	}
}