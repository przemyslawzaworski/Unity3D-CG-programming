Shader "Structured Buffer"
{
	SubShader 
	{
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0 			

			uniform StructuredBuffer<float4> A;
			uniform int resolution;

			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_Target
			{
				int x = int(round(ps.uv.x*resolution));
				int y = int(round(ps.uv.y*resolution));
				return A[y*resolution+x];
			}

			ENDCG
		}
	}
}