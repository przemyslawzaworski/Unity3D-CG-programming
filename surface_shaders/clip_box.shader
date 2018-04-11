Shader "Clip Box" 
{
	Properties 
	{ 
		_center ("Box Position", Vector) = (0,0,0,0)
		_scale ("Box Scale", Vector) = (1,1,1,1)		
		_MainTex ("Main Texture", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Metallic ("Metallic", Range(0,1)) = 1.0		
		_Smoothness ("Smoothness", Range(0,1)) = 0.0  
	}
	SubShader 
	{
		Tags { "RenderType" = "Opaque" }
		Cull Off
		CGPROGRAM
		#pragma surface surface_shader Standard fullforwardshadows
		#pragma target 3.0

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 worldPos;
		};

		float3 _center;
		float3 _scale;   
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Smoothness;
		half _Metallic;
		
		void surface_shader (Input IN, inout SurfaceOutputStandard o) 
		{
			float3 d = IN.worldPos - _center;
			float3 p = float3(abs(d.x),abs(d.y),abs(d.z));
			p.x = p.x - _scale.x * 0.5;
			p.y = p.y - _scale.y * 0.5;
			p.z = p.z - _scale.z * 0.5;
			float t = max(max(min(1.0,p.x),p.y),p.z);
			clip(t);        
			o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb ;
			o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;       
		}
		ENDCG
	} 
}