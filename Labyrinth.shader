Shader "Labyrinth"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			StructuredBuffer<uint> _StructuredBuffer;
			uint _GridSize;

			static const float3 _Vertices[36] = // vertices of single cube, in local space
			{
				{ 0.5, -0.5,  0.5}, { 0.5,  0.5,  0.5}, {-0.5,  0.5,  0.5},
				{ 0.5, -0.5,  0.5}, {-0.5,  0.5,  0.5}, {-0.5, -0.5,  0.5},
				{ 0.5,  0.5,  0.5}, { 0.5,  0.5, -0.5}, {-0.5,  0.5, -0.5},
				{ 0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5}, {-0.5,  0.5,  0.5},
				{ 0.5,  0.5, -0.5}, { 0.5, -0.5, -0.5}, {-0.5, -0.5, -0.5},
				{ 0.5,  0.5, -0.5}, {-0.5, -0.5, -0.5}, {-0.5,  0.5, -0.5},
				{ 0.5, -0.5, -0.5}, { 0.5, -0.5,  0.5}, {-0.5, -0.5,  0.5},
				{ 0.5, -0.5, -0.5}, {-0.5, -0.5,  0.5}, {-0.5, -0.5, -0.5},
				{-0.5, -0.5,  0.5}, {-0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5},
				{-0.5, -0.5,  0.5}, {-0.5,  0.5, -0.5}, {-0.5, -0.5, -0.5},
				{ 0.5, -0.5, -0.5}, { 0.5,  0.5, -0.5}, { 0.5,  0.5,  0.5},
				{ 0.5, -0.5, -0.5}, { 0.5,  0.5,  0.5}, { 0.5, -0.5,  0.5},
			};

			// extract single byte from four-bytes unsigned int number, index must have values from 0 to 3
			uint GetByteFromUint(uint number, uint index)
			{
				return (number >> (index << 3u)) & 0xFF;
			}

			// extract single bit from single byte, index must have values from 0 to 7
			uint GetBitFromByte(uint byte, uint index)
			{
				return ((byte >> index) & 0x01);
			}

			float4 VSMain (uint id : SV_VertexID, uint instance : SV_InstanceID, out float4 worldPos : WORLDPOS) : SV_POSITION
			{
				uint number = _StructuredBuffer[instance / 32u];
				uint byte = GetByteFromUint(number, (instance / 8u) % 4u);
				uint bit = GetBitFromByte(byte, instance % 8u);
				float3 offset = float3(instance % _GridSize, 0.0, instance / _GridSize);
				worldPos = (bit == 1) ? float4(_Vertices[id] + offset, 1.0) : asfloat(0x7fc00000);
				return UnityObjectToClipPos(worldPos);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float4 worldPos : WORLDPOS) : SV_Target
			{
				float3 dx = ddx(worldPos.xyz);
				float3 dy = ddy(worldPos.xyz);
				float3 nd = normalize(cross(dy, dx));
				float3 ld = normalize(_WorldSpaceLightPos0.xyz);
				float diffuse = max(dot(ld, nd), 0.0);
				return float4(diffuse.xxx + unity_AmbientSky, 1.0);
			}
			ENDCG
		}
	}
}