Shader "ProceduralSphereTessellation"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float _Radius;
			uint _TessellationFactor;

			float Mod (float x, float y)
			{
				return x - y * floor(x/y);
			}

			void GenerateSphere (uint id : SV_VertexID, float radius, uint tess, out float3 position, out float3 normal, out float2 texcoord)
			{
				int instance = int(floor(id / 6.0));
				float x = sign(Mod(20.0, Mod(float(id), 6.0) + 2.0));
				float y = sign(Mod(18.0, Mod(float(id), 6.0) + 2.0));
				float u = (float(instance / tess) + x) / float(tess);
				float v = (Mod(float(instance), float(tess)) + y) / float(tess);
				float pi = 3.14159265359;
				float a = sin(pi * u) * cos(2.0 * pi * v);
				float b = sin(pi * u) * sin(2.0 * pi * v);
				float c = cos(pi * u);
				position = float3(a, b, c) * radius;
				normal = normalize(position);
				texcoord = float2(u, v);
			}

			float4 VSMain (uint vertexId : SV_VertexID, out float3 normal : NORMAL, out float2 texcoord : TEXCOORD0) : SV_POSITION
			{
				float3 position = 0;
				GenerateSphere (vertexId, _Radius, _TessellationFactor, position, normal, texcoord);
				return UnityObjectToClipPos(float4(position, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 normal : NORMAL, float2 texcoord : TEXCOORD0) : SV_Target
			{
				return float4(max(dot(normalize(_WorldSpaceLightPos0).xyz, normal),0.0).xxx + UNITY_LIGHTMODEL_AMBIENT, 1.0);
			}
			ENDCG
		}
	}
}