Shader "Marching Cubes"
{
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Cull Off
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain
			#pragma target 5.0

			static const float _Scale = 20.0;

			struct Interpolators
			{
				float4 vertex : SV_Position;
				float2 barycentric : BARYCENTRIC;
				float3 normal : NORMAL;
				float3 color : COLOR;
			};

			struct Point
			{
				float3 position;
				float3 normal;
				float3 color;
			};

			struct Triangle
			{
				Point vertex[3];
			};

			uniform StructuredBuffer<Triangle> _TriangleBuffer;
			uniform int _Wireframe;
			uniform int _ShowNormals;

			void VSMain(inout float4 vertex : POSITION, out float3 color : COLOR, out float3 normal : NORMAL, uint id : SV_VertexID) 
			{
				uint pid = id / 3;
				uint vid = id % 3;
				vertex = UnityObjectToClipPos(float4(_Scale * _TriangleBuffer[pid].vertex[vid].position, 1));
				color = _TriangleBuffer[pid].vertex[vid].color;
				normal = _TriangleBuffer[pid].vertex[vid].normal;
			}

			[maxvertexcount(3)] 
			void GSMain( triangle float4 patch[3]:SV_Position, triangle float3 color[3]:COLOR, triangle float3 normal[3]:NORMAL, inout TriangleStream<Interpolators> stream)
			{
				Interpolators GS;
				for (uint i = 0; i < 3; i++)
				{
					GS.vertex = patch[i];
					GS.barycentric = float2(fmod(i,2.0), step(2.0,i));
					GS.normal = normal[i];
					GS.color = color[i];
					stream.Append(GS);
				}
				stream.RestartStrip();
			}

			float4 PSMain(Interpolators PS) : SV_Target
			{
				float3 coord = float3(PS.barycentric, 1.0 - PS.barycentric.x - PS.barycentric.y);
				coord = smoothstep(fwidth(coord)*0.1, fwidth(coord)*0.1 + fwidth(coord), coord);
				return float4(_ShowNormals ? PS.normal : PS.color, 1.0 - min(coord.x, min(coord.y, coord.z)) * _Wireframe);
			}
			ENDCG
		}
	}
}