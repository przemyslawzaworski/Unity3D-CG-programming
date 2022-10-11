Shader "Vertex Shader Tessellation Standard"
{
	Properties
	{
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}
	Subshader
	{
		Tags { "RenderType" = "Opaque" }
		Cull [_CullMode]
		CGPROGRAM
		#pragma surface SurfaceShader Standard vertex:VSMain fullforwardshadows addshadow
		#pragma target 5.0

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
			float2 texcoord2 : TEXCOORD2;
			float2 texcoord3 : TEXCOORD3;
			float4 color : COLOR;
			uint id : SV_VertexID;
		};

		struct Input
		{
			float2 uv_texcoord;
		};

		#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12)
			ByteAddressBuffer _VertexBuffer, _IndexBuffer;
			cbuffer _ConstantBuffer
			{
				int VertexOffset;
				int NormalOffset;
				int TangentOffset;
				int ColorOffset;
				int Texcoord0Offset;
				int Texcoord1Offset;
				int Texcoord2Offset;
				int Texcoord3Offset;
			};
		#endif
		int _TessellationFactor, _Dimension;
		float _Phong;

		// decode one 32-bit unsigned number to two 16-bit unsigned numbers
		uint2 AsUint16 (uint a)
		{
			uint x = a >> 16;
			uint y = a & 0xFFFF;
			return uint2(x, y);
		}

		// modulo division
		float Mod (float x, float y)
		{
			return x - y * floor(x/y);
		}

		void Tessellation (uint id, out float3 p, out float3 n, out float4 tg, out float4 col, out float2 t0, out float2 t1, out float2 t2, out float2 t3)
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
			uint vertexID = ((id / 3u) / subtriangles) * 3u + (id % 3u);
			uint offset = (vertexID / 6u) * 3;
			uint3 indices;
			#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12)
				indices = _IndexBuffer.Load3(offset << 2);
			#endif
			uint2 a = AsUint16(indices.x);
			uint2 b = AsUint16(indices.y);
			uint2 c = AsUint16(indices.z);
			float remainder = Mod(float((vertexID / 3u)), 2.0);
			uint f1 = (remainder == 0.0) ? a.y : b.x;
			uint f2 = (remainder == 0.0) ? a.x : c.y;
			uint f3 = (remainder == 0.0) ? b.y : c.x;
			float3 p1, p2, p3, n1, n2, n3;
			float4 tan1, tan2, tan3, col1, col2, col3;
			float2 tx01, tx02, tx03, tx11, tx12, tx13, tx21, tx22, tx23, tx31, tx32, tx33;
			#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12)
				p1   = asfloat(_VertexBuffer.Load3((f1 * _Dimension) + VertexOffset << 2));
				p2   = asfloat(_VertexBuffer.Load3((f2 * _Dimension) + VertexOffset << 2));
				p3   = asfloat(_VertexBuffer.Load3((f3 * _Dimension) + VertexOffset << 2));
				n1   = asfloat(_VertexBuffer.Load3((f1 * _Dimension) + NormalOffset << 2));
				n2   = asfloat(_VertexBuffer.Load3((f2 * _Dimension) + NormalOffset << 2));
				n3   = asfloat(_VertexBuffer.Load3((f3 * _Dimension) + NormalOffset << 2));
				tan1 = asfloat(_VertexBuffer.Load4((f1 * _Dimension) + TangentOffset << 2));
				tan2 = asfloat(_VertexBuffer.Load4((f2 * _Dimension) + TangentOffset << 2));
				tan3 = asfloat(_VertexBuffer.Load4((f3 * _Dimension) + TangentOffset << 2));
				col1 = asfloat(_VertexBuffer.Load4((f1 * _Dimension) + ColorOffset << 2));
				col2 = asfloat(_VertexBuffer.Load4((f2 * _Dimension) + ColorOffset << 2));
				col3 = asfloat(_VertexBuffer.Load4((f3 * _Dimension) + ColorOffset << 2));
				tx01 = asfloat(_VertexBuffer.Load2((f1 * _Dimension) + Texcoord0Offset << 2));
				tx02 = asfloat(_VertexBuffer.Load2((f2 * _Dimension) + Texcoord0Offset << 2));
				tx03 = asfloat(_VertexBuffer.Load2((f3 * _Dimension) + Texcoord0Offset << 2));
				tx11 = asfloat(_VertexBuffer.Load2((f1 * _Dimension) + Texcoord1Offset << 2));
				tx12 = asfloat(_VertexBuffer.Load2((f2 * _Dimension) + Texcoord1Offset << 2));
				tx13 = asfloat(_VertexBuffer.Load2((f3 * _Dimension) + Texcoord1Offset << 2));
				tx21 = asfloat(_VertexBuffer.Load2((f1 * _Dimension) + Texcoord2Offset << 2));
				tx22 = asfloat(_VertexBuffer.Load2((f2 * _Dimension) + Texcoord2Offset << 2));
				tx23 = asfloat(_VertexBuffer.Load2((f3 * _Dimension) + Texcoord2Offset << 2));
				tx31 = asfloat(_VertexBuffer.Load2((f1 * _Dimension) + Texcoord3Offset << 2));
				tx32 = asfloat(_VertexBuffer.Load2((f2 * _Dimension) + Texcoord3Offset << 2));
				tx33 = asfloat(_VertexBuffer.Load2((f3 * _Dimension) + Texcoord3Offset << 2));
			#endif
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
			float3 location = float3(u * p1 + v * p2 + w * p3);
			float3 d1 = location - n1 * (dot(location, n1) - dot(p1, n1));
			float3 d2 = location - n2 * (dot(location, n2) - dot(p2, n2));
			float3 d3 = location - n3 * (dot(location, n3) - dot(p3, n3));
			p = _Phong * (d1 * u + d2 * v + d3 * w) + (1.0 - _Phong) * location;
			n = float3(u * n1 + v * n2 + w * n3);
			tg = float4(u * tan1 + v * tan2 + w * tan3);
			col = float4(u * col1 + v * col2 + w * col3);
			t0 = float2(u * tx01 + v * tx02 + w * tx03);
			t1 = float2(u * tx11 + v * tx12 + w * tx13);
			t2 = float2(u * tx21 + v * tx22 + w * tx23);
			t3 = float2(u * tx31 + v * tx32 + w * tx33);
		}

		void VSMain(inout appdata v)
		{
			float3 position = 0;
			float3 normal = 0;
			float4 tangent = 0;
			float4 color = 0;
			float2 texcoord = 0;
			float2 texcoord1 = 0;
			float2 texcoord2 = 0;
			float2 texcoord3 = 0;
			Tessellation(v.id, position, normal, tangent, color, texcoord, texcoord1, texcoord2, texcoord3);
			v.vertex = float4(position, 1.0);
			v.normal = normal;
			v.tangent = tangent;
			v.color = color;
			v.texcoord = texcoord;
			v.texcoord1 = texcoord1;
			v.texcoord2 = texcoord2;
			v.texcoord3 = texcoord3;
		}

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = float4(1,1,1,1);
			o.Normal = float3(0,0,1);
			o.Metallic = 0.0; 
			o.Smoothness = 0.0; 
		}

		ENDCG
	}
}