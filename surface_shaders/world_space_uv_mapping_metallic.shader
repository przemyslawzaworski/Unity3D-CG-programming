Shader "World Space UV Mapping Metallic"
{
	Properties
	{
		_AlbedoMap ("Albedo Map", 2D) = "black" {}
		_NormalMap ("Normal Map", 2D) = "black" {}
		_MetallicMap ("Metallic (R) Smoothness(A) Map", 2D) = "black" {}
	}
	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface surface_shader Standard fullforwardshadows

		sampler2D _AlbedoMap,_NormalMap,_MetallicMap;
			
		struct Input 
		{
			float3 worldPos;
		};
			
		void surface_shader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = tex2Dlod(_AlbedoMap,float4(IN.worldPos.xz,0,0));
			o.Normal = UnpackNormal (tex2Dlod (_NormalMap, float4(IN.worldPos.xz,0,0)));
			o.Metallic = tex2Dlod(_MetallicMap, float4(IN.worldPos.xz,0,0)).r;
			o.Smoothness = tex2Dlod(_MetallicMap, float4(IN.worldPos.xz,0,0)).a;
		}				
		ENDCG		
	}
}