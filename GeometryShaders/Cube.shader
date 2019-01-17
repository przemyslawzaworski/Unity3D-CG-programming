Shader "Cube"
{
	SubShader
	{
		Cull Off
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain
			#pragma target 5.0

			static const float map[108] =   // vertices coordinates
			{
				-0.5f, -0.5f, -0.5f,
				-0.5f, -0.5f,  0.5f,
				-0.5f,  0.5f,  0.5f, 
				 0.5f,  0.5f, -0.5f, 
				-0.5f, -0.5f, -0.5f,
				-0.5f,  0.5f, -0.5f, 
				 0.5f, -0.5f,  0.5f,
				-0.5f, -0.5f, -0.5f,
				 0.5f, -0.5f, -0.5f,
				 0.5f,  0.5f, -0.5f,
				 0.5f, -0.5f, -0.5f,
				-0.5f, -0.5f, -0.5f,
				-0.5f, -0.5f, -0.5f,
				-0.5f,  0.5f,  0.5f,
				-0.5f,  0.5f, -0.5f,
				 0.5f, -0.5f,  0.5f,
				-0.5f, -0.5f,  0.5f,
				-0.5f, -0.5f, -0.5f,
				-0.5f,  0.5f,  0.5f,
				-0.5f, -0.5f,  0.5f,
				 0.5f, -0.5f,  0.5f,
				 0.5f,  0.5f,  0.5f,
				 0.5f, -0.5f, -0.5f,
				 0.5f,  0.5f, -0.5f,
				 0.5f, -0.5f, -0.5f,
				 0.5f,  0.5f,  0.5f,
				 0.5f, -0.5f,  0.5f,
				 0.5f,  0.5f,  0.5f,
				 0.5f,  0.5f, -0.5f,
				-0.5f,  0.5f, -0.5f,
				 0.5f,  0.5f,  0.5f,
				-0.5f,  0.5f, -0.5f,
				-0.5f,  0.5f,  0.5f,
				 0.5f,  0.5f,  0.5f,
				-0.5f,  0.5f,  0.5f,
				 0.5f, -0.5f,  0.5f
			};

			static const float uv[72] =   // UV coordinates
			{
				1.0f, 0.0f,
				0.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				0.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				1.0f, 1.0f,
				1.0f, 0.0f,
				0.0f, 0.0f,
				1.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				1.0f, 0.0f,
				0.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				1.0f, 0.0f,
				0.0f, 0.0f,
				1.0f, 1.0f,
				0.0f, 0.0f,
				0.0f, 1.0f,
				0.0f, 0.0f,
				1.0f, 1.0f,
				1.0f, 0.0f,
				1.0f, 0.0f,
				0.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 0.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				0.0f, 1.0f,
				1.0f, 1.0f,
				0.0f, 0.0f
			};

			struct Structure
			{
				float4 vertex : SV_Position;
				float2 uv : TEXCOORD0;
			};

			Structure VSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				Structure VS;
				VS.uv = uv;
				VS.vertex = vertex;
				return VS;
			}

			[maxvertexcount(36)] 
			void GSMain( triangle Structure patch[3], inout TriangleStream<Structure> stream, uint id : SV_PRIMITIVEID )
			{
				Structure GS;
				if (id == 0)
				{
					for (int i=0; i<12; i++)
					{
						GS.vertex = UnityObjectToClipPos(float4(map[i*9+0], map[i*9+1], map[i*9+2],1.0));
						GS.uv = float2(uv[i*6+0], uv[i*6+1]);
						stream.Append(GS);
						GS.vertex = UnityObjectToClipPos(float4(map[i*9+3], map[i*9+4], map[i*9+5],1.0));
						GS.uv = float2(uv[i*6+2], uv[i*6+3]);
						stream.Append(GS);
						GS.vertex = UnityObjectToClipPos(float4(map[i*9+6], map[i*9+7], map[i*9+8],1.0));
						GS.uv = float2(uv[i*6+4], uv[i*6+5]);
						stream.Append(GS);
						stream.RestartStrip();
					}
				}
			}

			float4 PSMain(Structure PS) : SV_Target
			{
				float2 k = sign(cos(PS.uv*32.0));
				return (k.x * k.y).xxxx;
			}
			ENDCG
		}
	}
}