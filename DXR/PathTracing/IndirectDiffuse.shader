Shader "IndirectDiffuse"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
	
			void VSMain (inout float4 vertex:POSITION, inout float3 normal:NORMAL)
			{
				vertex = UnityObjectToClipPos(vertex);
				normal = normalize(mul((float3x3)unity_ObjectToWorld,normal));
			}

			float4 PSMain (float4 vertex:POSITION, float3 normal:NORMAL) : SV_Target
			{
				return float4(dot(_WorldSpaceLightPos0.xyz, normal).xxx, 1.0);
			}
			
			ENDCG
		}

		Pass
		{
			Name "PathTracingRTX"
			Tags{ "LightMode" = "PathTracingRTX" }

			HLSLPROGRAM
			#pragma raytracing RTMain

//-------------------------------------------- Unity-Built-in-Shaders/CGIncludes/UnityRayTracingMeshUtils.cginc			
			#define MAX_VERTEX_STREAM_COUNT 4

			uint unity_MeshIndexSize_RT;                                         // 0 when an index buffer is not used, 2 for 16-bit indices or 4 for 32-bit indices.
			uint unity_MeshVertexSize_RT/*[MAX_VERTEX_STREAM_COUNT]*/;           // The stride between 2 consecutive vertices in the vertex buffer. Only one vertex stream is supported at this moment.
			uint unity_MeshBaseVertex_RT;                                        // A value added to each index before reading a vertex from the vertex buffer.
			uint unity_MeshIndexStart_RT;                                        // The location of the first index to read from the index buffer.
			uint unity_MeshStartVertex_RT;                                       // Index of the first vertex - used when an index buffer is not used.

			struct VertexAttributeInfo
			{
				uint InputSlot;         // Not supported. Always assumed to be 0.
				uint Format;
				uint ByteOffset;
				uint Dimension;
			};

			#define kVertexAttributePosition    0
			#define kVertexAttributeNormal      1
			#define kVertexAttributeTexCoord0   4

			#define kVertexFormatFloat          0
			#define kVertexFormatFloat16        1

			StructuredBuffer<VertexAttributeInfo> unity_MeshVertexDeclaration_RT;

			ByteAddressBuffer unity_MeshVertexBuffer_RT/*[MAX_VERTEX_STREAM_COUNT]*/;    // Only one vertex stream is supported at this moment.
			ByteAddressBuffer unity_MeshIndexBuffer_RT;

			uint3 UnityRayTracingFetchTriangleIndices(uint primitiveIndex)
			{
				uint3 indices;
				if (unity_MeshIndexSize_RT == 2)
				{
					const uint offsetInBytes = (unity_MeshIndexStart_RT + primitiveIndex * 3) << 1;
					const uint dwordAlignedOffset = offsetInBytes & ~3;
					const uint2 fourIndices = unity_MeshIndexBuffer_RT.Load2(dwordAlignedOffset);
					if (dwordAlignedOffset == offsetInBytes)
					{
						indices.x = fourIndices.x & 0xffff;
						indices.y = (fourIndices.x >> 16) & 0xffff;
						indices.z = fourIndices.y & 0xffff;
					}
					else
					{
						indices.x = (fourIndices.x >> 16) & 0xffff;
						indices.y = fourIndices.y & 0xffff;
						indices.z = (fourIndices.y >> 16) & 0xffff;
					}
					indices = indices + unity_MeshBaseVertex_RT.xxx;
				}
				else if (unity_MeshIndexSize_RT == 4)
				{
					const uint offsetInBytes = (unity_MeshIndexStart_RT + primitiveIndex * 3) << 2;
					indices = unity_MeshIndexBuffer_RT.Load3(offsetInBytes) + unity_MeshBaseVertex_RT.xxx;
				}
				else // unity_RayTracingMeshIndexSize == 0
				{
					const uint firstVertexIndex = primitiveIndex * 3 + unity_MeshStartVertex_RT;
					indices = firstVertexIndex.xxx + uint3(0, 1, 2);
				}
				return indices;
			}

			float2 UnityRayTracingFetchVertexAttribute2(uint vertexIndex, uint attributeType)
			{
				const uint attributeByteOffset  = unity_MeshVertexDeclaration_RT[attributeType].ByteOffset;
				const uint attributeDimension   = unity_MeshVertexDeclaration_RT[attributeType].Dimension;
				if (attributeByteOffset == 0xFFFFFFFF || attributeDimension < 2) return float2(0, 0);
				const uint vertexAddress    = vertexIndex * unity_MeshVertexSize_RT;
				const uint attributeAddress = vertexAddress + attributeByteOffset;
				const uint attributeFormat  = unity_MeshVertexDeclaration_RT[attributeType].Format;
				if (attributeFormat == kVertexFormatFloat)
				{
					return asfloat(unity_MeshVertexBuffer_RT.Load2(attributeAddress));
				}
				else if (attributeFormat == kVertexFormatFloat16)
				{
					const uint twoHalfs = unity_MeshVertexBuffer_RT.Load(attributeAddress);
					return float2(f16tof32(twoHalfs), f16tof32(twoHalfs >> 16));
				}
				else return float2(0, 0);
			}

			float3 UnityRayTracingFetchVertexAttribute3(uint vertexIndex, uint attributeType)
			{
				const uint attributeByteOffset  = unity_MeshVertexDeclaration_RT[attributeType].ByteOffset;
				const uint attributeDimension   = unity_MeshVertexDeclaration_RT[attributeType].Dimension;
				if (attributeByteOffset == 0xFFFFFFFF || attributeDimension < 3) return float3(0, 0, 0);
				const uint vertexAddress    = vertexIndex * unity_MeshVertexSize_RT;
				const uint attributeAddress = vertexAddress + attributeByteOffset;
				const uint attributeFormat  = unity_MeshVertexDeclaration_RT[attributeType].Format;
				if (attributeFormat == kVertexFormatFloat)
				{
					return asfloat(unity_MeshVertexBuffer_RT.Load3(attributeAddress));
				}
				else if (attributeFormat == kVertexFormatFloat16)
				{
					const uint2 fourHalfs = unity_MeshVertexBuffer_RT.Load2(attributeAddress);
					return float3(f16tof32(fourHalfs.x), f16tof32(fourHalfs.x >> 16), f16tof32(fourHalfs.y));
				}
				else return float3(0, 0, 0);
			}

//-------------------------------------------------------------------------------------------
			
			static const uint MaxDepth = 2;
			RaytracingAccelerationStructure  _AccelerationStructure;
			
			struct RayPayload
			{
				float3 color;
				uint seed;
				uint depth;
			};
			
			struct AttributeData
			{
				float2 barycentrics;
			};

			struct Point
			{
				float3 position;
				float3 normal;
				float2 texcoord;
			};

			float3 Hash(inout uint seed)
			{
				seed = 1664525u * seed + 1013904223u;
				uint3 rng = uint3(seed, seed*16807u, seed*48271u);
				return float3((rng >> 1) & uint3(0x7fffffffU.xxx)) / float(0x7fffffff);
			}

			void FetchData(uint index, out Point vertex)
			{
				vertex.position = UnityRayTracingFetchVertexAttribute3(index, kVertexAttributePosition);
				vertex.normal = UnityRayTracingFetchVertexAttribute3(index, kVertexAttributeNormal);
				vertex.texcoord = UnityRayTracingFetchVertexAttribute2(index, kVertexAttributeTexCoord0);
			}

			void Intersection(AttributeData attributeData, out Point vertex)
			{
				uint3 indices = UnityRayTracingFetchTriangleIndices(PrimitiveIndex());
				Point v0, v1, v2;
				FetchData(indices.x, v0);
				FetchData(indices.y, v1);
				FetchData(indices.z, v2);
				float3 barycentric = float3(1.0 - attributeData.barycentrics.x - attributeData.barycentrics.y, attributeData.barycentrics.x, attributeData.barycentrics.y);
				vertex.position = v0.position * barycentric.x + v1.position * barycentric.y + v2.position * barycentric.z;
				vertex.normal = v0.normal * barycentric.x + v1.normal * barycentric.y + v2.normal * barycentric.z;
				vertex.texcoord = v0.texcoord * barycentric.x + v1.texcoord * barycentric.y + v2.texcoord * barycentric.z;
			}

			[shader("closesthit")]
			void ClosestHit(inout RayPayload rayPayload : SV_RayPayload, AttributeData attributeData : SV_IntersectionAttributes)
			{
				if(rayPayload.depth + 1 == MaxDepth) return;
				Point vertex;
				Intersection(attributeData, vertex);
				float3 worldNormal = normalize(mul((float3x3)ObjectToWorld3x4(), vertex.normal));
				float3 rayOrigin = WorldRayOrigin();
				float3 rayDirection = WorldRayDirection();
				float3 hitPos = rayOrigin + RayTCurrent() * rayDirection;
				float3 randomVector = Hash(rayPayload.seed) * 2 - 1;
				float3 scatterRayDir = normalize(worldNormal + randomVector);
				RayDesc ray = {hitPos, 0.001, scatterRayDir, 100};
				RayPayload payload = {float3(0.0, 0.0, 0.0), rayPayload.seed, rayPayload.depth + 1};
				TraceRay(_AccelerationStructure, 0, 0x0f, 0, 1, 0, ray, payload);
				rayPayload.color = payload.color;
			}

			ENDHLSL
		}
	}
}