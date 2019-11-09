Shader "Wireframe (Geometry Shader)"
{
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain
			#pragma target 5.0

			struct Data
			{
				float4 vertex : SV_Position;
				float2 barycentric : BARYCENTRIC;
			};

			void VSMain(inout float4 vertex:POSITION) { }

			[maxvertexcount(3)] 
			void GSMain( triangle float4 patch[3]:SV_Position, inout TriangleStream<Data> stream)
			{
				Data GS;
				for (uint i = 0; i < 3; i++)
				{
					GS.vertex = UnityObjectToClipPos(patch[i]);
					GS.barycentric = float2(fmod(i,2.0), step(2.0,i));
					stream.Append(GS);
				}
				stream.RestartStrip();
			}

			float4 PSMain(Data PS) : SV_Target
			{
				float3 coord = float3(PS.barycentric, 1.0 - PS.barycentric.x - PS.barycentric.y);
				coord = smoothstep(fwidth(coord)*0.1, fwidth(coord)*0.1 + fwidth(coord), coord);
				return float4(0..xxx, 1.0 - min(coord.x, min(coord.y, coord.z)));
			}
			ENDCG
		}
	}
}