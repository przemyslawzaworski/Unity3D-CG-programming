Shader "Nurbs Hair"
{
	Subshader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			uniform float3 _HairColor, _HairEnds;
			uniform float4 _HairPosition, _HairWeights;
			uniform float _HairScale, _HairEffect, _HairPower, _HairWind;
			uniform int _HairQuality, _HairShading, _HairNormalsMode, _HairDebugNormals;

			// L. Piegl, W. Tiller, "The NURBS Book", Springer Verlag, 1997
			// http://nurbscalculator.in/
			float3 NurbsCurve (float4 cps[4], int cpsLength, float knots[8], int knotsLength, float u)
			{
				const int degree = 3;
				for (int t = 0; t < cpsLength; t++) cps[t].xyz *= cps[t].w;
				int index = 0;
				float4 p = 0;
				int n = knotsLength - degree - 2;
				if (u == (knots[n + 1])) index = n;
				int low = degree;
				int high = n + 1;
				int mid = (int)floor((low + high) / 2.0);
				[unroll(16)]
				while (u < knots[mid] || u >= knots[mid + 1])
				{
					if (u < knots[mid])
						high = mid;
					else
						low = mid;
					mid = (int)floor((low + high) / 2.0);
				}
				index = mid;
				float N[degree + 1];
				float left[degree + 1];
				float right[degree + 1];
				float saved = 0.0, temp = 0.0;
				N[0] = 1.0;
				[loop] for (int j = 1; j <= degree; j++)
				{
					left[j] = (u - knots[index + 1 - j]);
					right[j] = knots[index + j] - u;
					saved = 0.0f;
					[loop] for (int r = 0; r < j; r++)
					{
						temp = N[r] / (right[r + 1] + left[j - r]);
						N[r] = saved + right[r + 1] * temp;
						saved = left[j - r] * temp;
					}
					N[j] = saved;
				}
				for (int i = 0; i <= degree; i++) p += cps[index - degree + i] * N[i];
				return (p.w != 0) ? p.xyz / p.w : p.xyz;
			}

			float3 NurbsCurveTangent (float4 cps[4], int cpsLength, float knots[8], int knotsLength, float u)
			{
				const int order = 1; // order of the derivative
				const int degree = 3; // curve degree
				float ders[order + 1][degree + 1];
				int span = 0;
				int n = knotsLength - degree - 2;
				if (u == (knots[n + 1])) span = n;
				int low = degree;
				int high = n + 1;
				int mid = (int)floor((low + high) / 2.0);
				[unroll(16)]
				while (u < knots[mid] || u >= knots[mid + 1])
				{
					if (u < knots[mid])
						high = mid;
					else
						low = mid;
					mid = (int)floor((low + high) / 2.0);
				}
				span = mid;
				float left[degree + 1];
				float right[degree + 1];
				float ndu[degree + 1][degree + 1];
				ndu[0][0] = 1.0;
				[loop] for (int j = 1; j <= degree; j++)
				{
					left[j] = u - knots[span + 1 - j];
					right[j] = knots[span + j] - u;
					float saved = 0.0;
					[loop] for (int r = 0; r < j; r++)
					{
						ndu[j][r] = right[r + 1] + left[j - r];
						float temp = ndu[r][j - 1] / ndu[j][ r];
						ndu[r][ j] = saved + right[r + 1] * temp;
						saved = left[j - r] * temp;
					}
					ndu[j][j] = saved;
				}
				for (int m = 0; m <= degree; m++) ders[0][m] = ndu[m][degree];
				float a[2][degree + 1];
				for (int r = 0; r <= degree; r++)
				{
					int s1 = 0;
					int s2 = 1;
					a[0][0] = 1.0;
					[unroll(order)]
					for (int k = 1; k <= order; k++)
					{
						float d = 0.0;
						int rk = r - k;
						int pk = degree - k;
						int j1 = 0;
						int j2 = 0;
						if (r >= k)
						{
							a[s2][0] = a[s1][0] / ndu[pk + 1][rk];
							d = a[s2][0] * ndu[rk][pk];
						}
						j1 = (rk >= -1) ? 1 : -rk;
						j2 = (r - 1 <= pk) ? k - 1 : degree - r;
						[loop] for (int j = j1; j <= j2; j++)
						{
							a[s2][j] = (a[s1][j] - a[s1][j - 1]) / ndu[pk + 1][rk + j];
							d += a[s2][j] * ndu[rk + j][pk];
						}
						if (r <= pk)
						{
							a[s2][k] = -a[s1][k - 1] / ndu[pk + 1][r];
							d += a[s2][k] * ndu[r][pk];
						}
						ders[k][r] = d;
						int s3 = s1;
						s1 = s2;
						s2 = s3;
					}
				}
				float f = degree;
				[unroll(order)]
				for (int k = 1; k <= order; k++)
				{
					for (int h = 0; h <= degree; h++) ders[k][ h] *= f;
					f *= degree - k;
				}
				int du = order < degree ? order : degree;
				float3 result[order + 1];
				for (int k = 0; k <= du; k++)
				{
					for (int j = 0; j <= degree; j++)
					{
						float4 v = cps[span - degree + j];
						result[k].xyz += v.xyz * ders[k][j];
					}
				}
				return normalize(result[1]);
			}

			float Mod (float x, float y)
			{
				return x - y * floor(x / y);
			}

			float4 Hash(uint p) // Returns value in range -1..1
			{
				p = 1103515245U*((p >> 1U)^(p));
				uint h32 = 1103515245U*((p)^(p>>3U));
				uint n = h32^(h32 >> 16);
				uint4 rz = uint4(n, n*16807U, n*48271U, n*69621U);
				return float4((rz >> 1) & (uint4)(0x7fffffffU)) / float(0x7fffffff) * 2.0 - 1.0;
			}

			float2 PolarToCartesian (float2 p)
			{
				return p.x * float2(cos(p.y), sin(p.y));
			}

			float4 VSMain (uint vertexId : SV_VertexID, out float3 color : COLOR, out float3 normal : NORMAL) : SV_POSITION
			{
				float strand = float(_HairQuality); // amount of vertices per strand, default is 64
				float instance = floor(vertexId / strand); // instance ID
				float id = Mod(vertexId, strand); // vertex ID
				float t = max((id + Mod(id, 2.0) - 1.0), 0.0) / (strand - 1.0); // interpolator
				float4 n = Hash(uint(instance + 123u)); // noise
				float2 k = PolarToCartesian (float2(n.x * 3.0, n.y * 16.0));
				float4 controlPoints[4] = {0..xxxx, 0..xxxx, 0..xxxx, 0..xxxx};
				float knotVector[8] = {0.0, 0.0, 0.0, 0.0, 1.0 - _HairEffect, 1.0, 1.0, 1.0};
				float wind = sin(_Time.g * n.x * _HairWind) * 0.1;
				controlPoints[0] = float4(0.0, 0.0, 0.0, _HairWeights.x);
				controlPoints[1] = float4(k.x / 4.0, n.z + 1, k.y / 4.0, _HairWeights.y);
				controlPoints[2] = float4(k.x / 2.0, n.w + 1, k.y / 2.0, _HairWeights.z);
				controlPoints[3] = float4(k.x, -1.0 + n.w * 0.5 + wind, k.y, _HairWeights.w);
				float3 localPos = NurbsCurve (controlPoints, 4, knotVector, 8, t) * _HairScale;
				normal = _HairNormalsMode > 0 ? normalize(localPos) : NurbsCurveTangent(controlPoints, 4, knotVector, 8, t);
				color = float4(lerp(_HairColor, _HairEnds, pow(t, _HairPower)), 1);
				return UnityObjectToClipPos(float4(localPos + _HairPosition.xyz, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 color : COLOR, float3 normal : NORMAL) : SV_Target
			{
				float angle = 1.0 - length(_WorldSpaceLightPos0.xz) / length(_WorldSpaceLightPos0.xyz);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normalDir = normalize(normal);
				float diffuse = max(dot(lightDir, normalDir), angle);
				return _HairDebugNormals > 0 ? float4(normalDir, 1.0) : (_HairShading > 0 ? float4(diffuse.xxx * color, 1.0) : float4(color, 1.0));
			}
			ENDCG
		}
	}
}