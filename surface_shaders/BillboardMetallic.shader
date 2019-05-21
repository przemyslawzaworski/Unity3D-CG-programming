Shader "Billboard Metallic"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo Map", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_MetallicGlossMap ("Metallic (R) Smoothness(A) Map", 2D) = "black" {}
	}

	Subshader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow vertex:vertexDataFunc

		sampler2D _MainTex, _BumpMap, _MetallicGlossMap;
		float4 _Color;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_MetallicGlossMap;
		};

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			v.vertex.xy *= float2(length(unity_ObjectToWorld._m00_m10_m20), length(unity_ObjectToWorld._m01_m11_m21));
			float3 forward = -normalize(UNITY_MATRIX_V._m20_m21_m22);
			float3 up = normalize(UNITY_MATRIX_V._m10_m11_m12);
			float3 right = normalize(UNITY_MATRIX_V._m00_m01_m02);
			float4x4 rotationMatrix = float4x4(right, 0, up, 0, forward, 0, 0, 0, 0, 1);
			v.vertex = mul(v.vertex, rotationMatrix);
			v.normal = mul(v.normal, rotationMatrix);
			v.vertex.xyz = mul((float3x3)unity_WorldToObject, v.vertex.xyz);
			v.normal = mul(v.normal, (float3x3)unity_ObjectToWorld);
		}
		
		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			float4 c = tex2D(_MainTex,IN.uv_MainTex);
			o.Albedo = c.rgb * _Color; 
			o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_BumpMap)); 
			o.Metallic = tex2D(_MetallicGlossMap, IN.uv_MetallicGlossMap).r; 
			o.Smoothness = tex2D(_MetallicGlossMap, IN.uv_MetallicGlossMap).a; 
			clip (c.a - 0.5);
		}

		ENDCG
	}
}