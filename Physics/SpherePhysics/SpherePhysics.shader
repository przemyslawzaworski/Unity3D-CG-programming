Shader "SpherePhysics" 
{
	Properties 
	{
		_Metallic ("Metallic", Range(0,1)) = 1.0	
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }      
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow
		#pragma instancing_options procedural:setup
		
		float _Smoothness, _Metallic;

		struct Input 
		{
			float2 uv_texcoord;
		};

		struct Sphere
		{
			float3 position;
			float3 velocity;
			float radius;
			float massInverse;
		};

		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			StructuredBuffer<Sphere> SphereBuffer;
			StructuredBuffer<float4> SpherePropsBuffer;
		#endif

		void setup()
		{
			#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
				Sphere sphere = SphereBuffer[unity_InstanceID];
				float s = sphere.radius * 2.0;
				unity_ObjectToWorld._11_21_31_41 = float4(s, 0, 0, 0);
				unity_ObjectToWorld._12_22_32_42 = float4(0, s, 0, 0);
				unity_ObjectToWorld._13_23_33_43 = float4(0, 0, s, 0);
				unity_ObjectToWorld._14_24_34_44 = float4(sphere.position, 1);
				unity_WorldToObject = unity_ObjectToWorld;
				unity_WorldToObject._14_24_34 *= -1;
				unity_WorldToObject._11_22_33 = 1.0f / unity_WorldToObject._11_22_33;
			#endif
		}

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{         
			o.Albedo = 1;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Alpha = 1.0;
			#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
				o.Albedo *= SpherePropsBuffer[unity_InstanceID].xyz;
				o.Smoothness *= SpherePropsBuffer[unity_InstanceID].w;
			#endif
		}
		ENDCG
	}
	FallBack "Diffuse"
}