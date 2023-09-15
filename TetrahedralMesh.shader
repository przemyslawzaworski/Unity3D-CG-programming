Shader "Hidden/TetrahedralMesh"
{
	Subshader
	{
		CGPROGRAM
		#pragma target 5.0
		#pragma surface SurfaceShaderMain Standard vertex:VertexShaderMain fullforwardshadows addshadow

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord1 : TEXCOORD1;
			float2 texcoord2 : TEXCOORD2;
			uint id : SV_VertexID;
			uint instance : SV_InstanceID;
		};

		#ifdef SHADER_API_D3D11
		StructuredBuffer<float4> _Vertices;
		#endif

		struct Input
		{
			float vface : VFACE;
		};

		void VertexShaderMain (inout appdata v, out Input o) 
		{
			#ifdef SHADER_API_D3D11
			uint i = (v.id / 3u) * 3u;
			v.vertex = (_Vertices[v.id].w > 0.5) ? _Vertices[v.id] : asfloat(0x7fc00000);
			v.normal = normalize(cross(_Vertices[i+1] - _Vertices[i+0], _Vertices[i+2] - _Vertices[i+1]));
			o.vface = 0;
			#endif
		}

		void SurfaceShaderMain (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = float4((float3) 0.5, 1.0); 
			o.Normal = float3(0, 0, IN.vface < 0 ? -1 : 1);
			o.Metallic = 0.0; 
			o.Smoothness = 0.0;
		}

		ENDCG
	}
}