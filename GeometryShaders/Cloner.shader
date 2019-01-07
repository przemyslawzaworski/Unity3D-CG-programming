Shader "Cloner"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_Offset ("Offset", Vector) = (2,0,0,0)		
	}
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

			sampler2D _MainTex;
			float4 _Offset;
			
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

			[maxvertexcount(6)] 
			void GSMain( triangle Structure patch[3], inout TriangleStream<Structure> stream )
			{
				Structure GS;
				for (uint i = 0; i < 3; i++)
				{
					GS.vertex = UnityObjectToClipPos(patch[i].vertex);
					GS.uv = patch[i].uv;
					stream.Append(GS);
				}
				stream.RestartStrip();
				for (uint k = 0; k < 3; k++)
				{
					GS.vertex = UnityObjectToClipPos(patch[k].vertex + _Offset);
					GS.uv = patch[k].uv;
					stream.Append(GS);
				}
				stream.RestartStrip();
			}

			float4 PSMain(Structure PS) : SV_Target
			{
				return tex2D(_MainTex,PS.uv);
			}
			ENDCG
		}
	}
}
