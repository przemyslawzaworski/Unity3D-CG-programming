// Description: https://forum.unity.com/threads/how-to-print-shaders-var-please.26052/#post-5160875

Shader "Debugger"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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

			struct Data
			{
				float4 vertex : SV_Position;
				float2 uv : TEXCOORD0;
				float number : VALUE;
			};
			
			// "PrintValue" function by P.Malin
			float PrintValue( float2 vCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
			{
				if ((vCoords.y < 0.0) || (vCoords.y >= 1.0)) return 0.0;  
				bool bNeg = ( fValue < 0.0 );
				fValue = abs(fValue);  
				float fBiggestIndex = max(floor(log2(abs(fValue)) / log2(10.0)), 0.0);
				float fDigitIndex = fMaxDigits - floor(vCoords.x);
				float fCharBin = 0.0;
				if(fDigitIndex > (-fDecimalPlaces - 1.01))
				{
					if(fDigitIndex > fBiggestIndex)
					{
						if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
					}
					else
					{
						if(fDigitIndex == -1.0)
						{
							if(fDecimalPlaces > 0.0) fCharBin = 2.0;
						}
						else
						{
							float fReducedRangeValue = fValue;
							if(fDigitIndex < 0.0) { fReducedRangeValue = frac( fValue ); fDigitIndex += 1.0; }
							float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
							int x = int(floor(fDigitValue - 10.0 * floor(fDigitValue/10.0)));  
							fCharBin = x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
						}
					}
				}
				float result = (fCharBin / pow(2.0, floor(frac(vCoords.x) * 4.0) + (floor(vCoords.y * 5.0) * 4.0)));
				return floor(result - 2.0 * floor(result/2.0)); 
			}
			
			Data VSMain( float4 vertex:POSITION, float2 uv:TEXCOORD0 )
			{
				Data VS;
				VS.uv = uv;
				VS.vertex = vertex;
				VS.number = 12.34;  //vertex shader variable value to print
				return VS;
			}

			[maxvertexcount(9)] 
			void GSMain( triangle Data patch[3], inout TriangleStream<Data> stream, uint id:SV_PRIMITIVEID )
			{
				Data GS;
				for (uint i = 0; i < 3; i++)
				{
					GS.vertex = UnityObjectToClipPos(patch[i].vertex);
					GS.uv = patch[i].uv;
					GS.number = patch[i].number;
					stream.Append(GS);
				}
				stream.RestartStrip();
				
				if (id == 0)  // determine quad
				{
					for (uint i = 0; i < 6; i++)
					{
						float u = float(i) - 2.0 * floor(float(i)/2.0);
						float v = sign(fmod(126.0,fmod(float(i),6.0)+6.0));
						GS.uv = float2(u, 1.0 - v) + 10000.0;  // UV offset
						GS.vertex = float4(sign(u)+0.5, sign(v)+0.5, 0.3, 1.0);
						GS.number = patch[0].number;
						stream.Append(GS);
					}
				}
				stream.RestartStrip();
			}

			float4 PSMain(Data PS) : SV_Target
			{
				float value = PS.number;
				if (PS.uv.x > 9000.0)  // determine quad
				{
					float2 font = float2(24.0, 30.0);
					float2 position = float2(_ScreenParams.x - 250.0, 15.0);
					float3 base = PrintValue( (PS.vertex.xy - position) / font, value, 6.0, 2.0).xxx;
					return float4(base, 1.0);
				}
				else return tex2D(_MainTex, PS.uv);
			}
			ENDCG
		}
	}
}