Shader "TriangleStrip"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			StructuredBuffer<float3> _ComputeBuffer;

			float3 Hash(uint q)
			{
				uint3 n = q * uint3(1597334673u, 3812015801u, 2798796415U);
				n = (n.x ^ n.y ^ n.z) * uint3(1597334673u, 3812015801u, 2798796415U);
				return float3(n.x, n.y, n.z) * (1.0 / float(0xffffffffu));
			}

			float4 VSMain (uint id : SV_VertexID, out float3 color : COLOR) : SV_POSITION
			{
				uint primitive = id / 3u;
				uint remainder = id % 3u;
				bool isEven = (primitive % 2u) == 0u;
				uint index = isEven ? primitive + remainder : primitive + abs(int(remainder) - 3) * sign(remainder);
				float3 position = _ComputeBuffer[index];
				color = Hash(primitive);
				return UnityObjectToClipPos(position);
			}
 
			float4 PSMain (float4 vertex : SV_POSITION, float3 color : COLOR) : SV_Target
			{
				return float4(color, 1.0);
			}
			ENDCG
		}
	}
}