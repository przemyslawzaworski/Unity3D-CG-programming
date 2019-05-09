Shader "Debris"
{
	Properties
	{
		_MainTex ("Albedo Map", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
	}

	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow vertex:vertexDataFunc
		#pragma target 4.5
		#pragma multi_compile_instancing

		sampler2D _MainTex, _BumpMap;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			#ifdef UNITY_INSTANCING_ENABLED
				float s = frac(sin(unity_InstanceID + 123) * 43758.5453123);
				v.vertex.xyz *= s.xxx;
			#endif
		}
		
		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex); 
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap));
			o.Metallic = 0.0; 
			o.Smoothness = 0.0; 
		}

		ENDCG
	}
}