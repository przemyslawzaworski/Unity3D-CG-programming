// GPU PRO 3, Advanced Rendering Techniques, A K Peters/CRC Press 2012
// Chapter 1 - Vertex shader tessellation, Holger Gruen

Shader "Vertex Shader Tessellation"
{
	SubShader
	{
		Pass
		{
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			ByteAddressBuffer  _VertexBuffer;
			int _TessellationFactor;

			float4 VSMain (uint id : SV_VertexID) : SV_POSITION
			{
				uint subtriangles = (_TessellationFactor * _TessellationFactor);
				float triangleID = float (( id / 3 ) % subtriangles);
				float row = floor (sqrt( triangleID ));
				uint column = triangleID - ( row * row );
				float incuv = 1.0 / _TessellationFactor;
				float u = ( 1.0 + row ) / _TessellationFactor;
				float v = incuv * floor (float(column) * 0.5);
				u -= v;
				float w = 1.0 - u - v;
				uint address = id / (3u * subtriangles) * 3u;
				float3 p1 = asfloat(_VertexBuffer.Load4(((address + 0) * 4) << 2)).xyz;
				float3 p2 = asfloat(_VertexBuffer.Load4(((address + 1) * 4) << 2)).xyz;
				float3 p3 = asfloat(_VertexBuffer.Load4(((address + 2) * 4) << 2)).xyz;
				uint vertexID = ((id / 3u) / subtriangles) * 3u + (id % 3u);
				switch(vertexID % 3)
				{
					case 0u:
						if ((column & 1u) != 0)
						{
							v += incuv, u -= incuv;
						}
						break;
					case 1u:
						if ((column & 1u) == 0)
						{
							v += incuv, u -= incuv;
						}
						else
						{
							v += incuv, u -= incuv;
							w += incuv, u -= incuv;
						}
						break;
					case 2u:
						if ((column & 1u) == 0)
						{
							u -= incuv, w += incuv;
						}
						else 
						{
							w += incuv, u -= incuv;
						}
						break;
				}
				return UnityObjectToClipPos(float4(u * p1 + v * p2 + w * p3, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION) : SV_TARGET
			{
				return (float4) 1.0;
			}
			ENDCG
		}
	}
}