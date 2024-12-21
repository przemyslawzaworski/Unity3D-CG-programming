Shader "Foam"
{
	Properties
	{
		_VoronoiColor ("Foam Color", Color) = (1,1,1,1)
		_VoronoiPower ("Foam Power", Range (0.0, 8.0)) = 1.5
		_VoronoiSmoothnessA ("Foam Smoothness A", Range (0.0, 1.0)) = 0.5
		_VoronoiSmoothnessB ("Foam Smoothness B", Range (0.0, 1.0)) = 0.5
		_VoronoiSmoothnessC ("Foam Smoothness C", Range (0.0, 1.0)) = 0.5
		_VoronoiSpeedA ("Foam Speed A", Range (0.0, 1.0)) = 0.5
		_VoronoiSpeedB ("Foam Speed B", Range (0.0, 1.0)) = 0.5
		_VoronoiSpeedC ("Foam Speed C", Range (0.0, 1.0)) = 0.5
		_VoronoiScaleA ("Foam Scale A", Range (0.0, 256.0)) = 150.0
		_VoronoiScaleB ("Foam Scale B", Range (0.0, 256.0)) = 100.0
		_VoronoiScaleC ("Foam Scale C", Range (0.0, 256.0)) = 50.0
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			struct Attributes
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float _VoronoiPower;
			float4 _VoronoiColor;
			float _VoronoiSmoothnessA;
			float _VoronoiSmoothnessB;
			float _VoronoiSmoothnessC;
			float _VoronoiSpeedA;
			float _VoronoiSpeedB;
			float _VoronoiSpeedC;
			float _VoronoiScaleA;
			float _VoronoiScaleB;
			float _VoronoiScaleC;

			float3 Hash(float2 p)
			{
				float a = dot(p, float2(127.1, 311.7));
				float b = dot(p, float2(269.5, 183.3));
				float c = dot(p, float2(419.2, 371.9));
				return frac(sin(float3(a, b, c)) * 43758.5453);
			}

			float Voronoi(float2 uv, float weight, float speed)
			{
				float2 cell = floor(uv);
				float2 fraction = frac(uv);
				float minDistance = 8.0;
				for(int j=-1; j<=1; j++)
				{
					for(int i=-1; i<=1; i++)
					{
						float2 offset = float2(float(i), float(j));
						float2 neighbor = cell + offset;
						float3 hash = Hash(neighbor);
						float currentDistance = length(offset - fraction + hash.xy);
						float scale = hash.x * hash.y;
						float time = frac(_Time.g * speed);
						if (hash.z < time) scale = scale * time;
						currentDistance += scale;
						float blendFactor = smoothstep(-1.0, 1.0, (minDistance - currentDistance) / weight);
						minDistance = lerp(minDistance, currentDistance, blendFactor);
						minDistance -= blendFactor * (1.0 - blendFactor) * weight / (1.0 + 3.0 * weight);
					}
				}
				return minDistance;
			}

			float Foam(float2 p)
			{
				float layer1 = Voronoi(_VoronoiScaleA * p, _VoronoiSmoothnessA, _VoronoiSpeedA);
				float layer2 = Voronoi(_VoronoiScaleB * p, _VoronoiSmoothnessB, _VoronoiSpeedB);
				float layer3 = Voronoi(_VoronoiScaleC * p, _VoronoiSmoothnessC, _VoronoiSpeedC);
				return pow(min(min(layer1, layer2), layer3), _VoronoiPower);
			}

			Varyings VSMain (Attributes IN)
			{
				Varyings OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;
				return OUT;
			}

			float4 PSMain (Varyings IN) : SV_Target
			{
				float foam = Foam(IN.uv);
				return float4(foam * _VoronoiColor.rgb, foam);
			}
			
			ENDCG
		}
	}
}