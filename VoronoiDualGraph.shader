Shader "Hidden/VoronoiDualGraph"
{
	SubShader
	{
		Cull Off
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			struct Triangle
			{
				float2 Vertices[3];
			};

			uniform StructuredBuffer<Triangle> _TriangleBuffer;

			float4 VSMain (float4 vertex : POSITION, uint id : SV_VertexID, out float2 barycentric : BARYCENTRIC) : SV_Position
			{
				uint index = id % 3u;
				float3 worldPos = float3(_TriangleBuffer[id / 3u].Vertices[index], 0.02);
				barycentric = float2(fmod(index, 2.0), step(2.0, index));
				return UnityObjectToClipPos(float4(worldPos.xzy, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float2 barycentric : BARYCENTRIC) : SV_Target
			{
				float3 coords = float3(barycentric, 1.0 - barycentric.x - barycentric.y);
				float3 df = fwidth(coords);
				float3 wireframe = smoothstep(df * 0.1, df * 0.1 + df, coords);
				if ((1.0 - min(wireframe.x, min(wireframe.y, wireframe.z))) < 0.01) discard;
				return float4(0.0, 0.0, 0.0, 1.0);
			}
			ENDCG
		}
	}
}