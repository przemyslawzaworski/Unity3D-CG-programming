Shader "PBR Double Sided Color"
{
	Properties
	{
		_color ("Color", Color) = (0.5,0.5,0.5,1.0)
	}
	Subshader
	{
		Cull Off
		CGPROGRAM
		#pragma surface surface_shader Standard fullforwardshadows
			
		float4 _color;
			
		struct Input 
		{
			float2 uv_MainTex;
		};
		
		void surface_shader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = _color;
		}

		ENDCG		
	}
}