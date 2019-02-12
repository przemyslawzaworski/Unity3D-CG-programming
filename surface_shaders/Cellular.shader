Shader "Cellular"
{
	Properties
	{
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}
	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow

		struct Input
		{
			float2 uv_texcoord;
		};

		float shape( float2 p )
		{
			return dot(frac(p)-0.5, frac(p)-0.5);    
		}

		float cell( float2 p )
		{
			float c = 0.5;
			c = min(c, shape(p - float2(0.80, 0.61)));
			c = min(c, shape(p - float2(0.36, 0.20)));  
			c = min(c, shape(p - float2(0.60, 0.24)));
			c = min(c, shape(p - float2(0.18, 0.82)));
			p *= 1.4142;      
			c = min(c, shape(p - float2(0.45, 0.30)));
			c = min(c, shape(p - float2(0.04, 0.88))); 
			c = min(c, shape(p - float2(0.06, 0.54)));
			c = min(c, shape(p - float2(0.64, 0.12)));      
			return sqrt(c*5.); 
		}

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			float2 uv = float2(2.0 * IN.uv_texcoord.xy - 1.0);
			o.Albedo = float4(cell(uv).xxx + (cell(uv*5.)) * 0.05, 1.0); 
			o.Normal = float3(0.0,0.0,1.0); 
			o.Metallic = 0.0; 
			o.Smoothness = 0.0;
		}

		ENDCG
	}
}