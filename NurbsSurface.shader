Shader "Nurbs Surface"
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

			uint _TessellationFactor, _NormalsMode;

			// Sphere: https://geometrictools.com/Documentation/NURBSCircleSphere.pdf
			static float4 ControlPoints[4][7] =
			{
				{float4(0, 0,  1, 1.0000), float4(0, 0,  1, 0.3333), float4( 0, 0,  1, 0.3333), float4( 0, 0,  1, 1.0000), float4(  0,  0,  1, 0.3333), float4( 0,  0,  1, 0.3333), float4( 0, 0,  1, 1.0000)},
				{float4(2, 0,  1, 0.3333), float4(2, 4,  1, 0.1111), float4(-2, 4,  1, 0.1111), float4(-2, 0,  1, 0.3333), float4( -2, -4,  1, 0.1111), float4( 2, -4,  1, 0.1111), float4( 2, 0,  1, 0.3333)},
				{float4(2, 0, -1, 0.3333), float4(2, 4, -1, 0.1111), float4(-2, 4, -1, 0.1111), float4(-2, 0, -1, 0.3333), float4( -2, -4, -1, 0.1111), float4( 2, -4, -1, 0.1111), float4( 2, 0, -1, 0.3333)},
				{float4(0, 0, -1, 1.0000), float4(0, 0, -1, 0.3333), float4( 0, 0, -1, 0.3333), float4( 0, 0, -1, 1.0000), float4(  0,  0, -1, 0.1111), float4( 0,  0, -1, 0.1111), float4( 0, 0, -1, 1.0000)}
			};

			static float KnotVectors[11][2] = // knotsDim = (8, 11)
			{
				{0.0, 0.0},
				{0.0, 0.0},
				{0.0, 0.0},
				{0.0, 0.0},
				{1.0, 0.5},
				{1.0, 0.5},
				{1.0, 0.5},
				{1.0, 1.0},
				{0.0, 1.0},
				{0.0, 1.0},
				{0.0, 1.0}
			};

			// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/mod.xhtml
			float Mod (float x, float y)
			{
				return x - y * floor(x / y);
			}

			// https://developer.nvidia.com/sites/all/modules/custom/gpugems/books/GPUGems/gpugems_ch25.html
			float Checkerboard(float2 uv)
			{
				float2 fw = max(abs(ddx_fine(uv)), abs(ddy_fine(uv)));
				float width = max(fw.x, fw.y);
				float2 p0 = uv - 0.5 * width, p1 = uv + 0.5 * width;
				#define BUMPINT(x) (floor((x)/2) + 2.f * max(((x)/2) - floor((x)/2) - .5f, 0.f))
				float2 i = (BUMPINT(p1) - BUMPINT(p0)) / width;
				return i.x * i.y + (1 - i.x) * (1 - i.y);
			}
 
			// L. Piegl, W. Tiller, "The NURBS Book", Springer Verlag, 1997
			// http://nurbscalculator.in/
			float3 NurbsSurface (float4 cps[4][7], int2 cpsDim, float knots[11][2], int2 knotsDim, float2 uv)
			{
				const int2 degree = int2(3, 3);
				#define msize max(degree.x, degree.y)
				for (int x = 0; x < cpsDim[0]; x++)
				{
					for (int y = 0; y < cpsDim[1]; y++)
					{
						cps[x][y].xyz *= cps[x][y].w;
					}
				}
				int2 spans = int2(0, 0);
				float4 p = 0;
				[unroll(2)] for (int i = 0; i < 2; i++)
				{
					int n = knotsDim[i] - degree[i] - 2;
					if (uv[i] == (knots[n + 1][i])) spans[i] = n;
					int low = degree[i];
					int high = n + 1;
					int mid = (int)floor((low + high) / 2.0);
					[unroll(16)]
					while (uv[i] < knots[mid][i] || uv[i] >= knots[mid + 1][i])
					{
						if (uv[i] < knots[mid][i])
							high = mid;
						else
							low = mid;
						mid = (int)floor((low + high) / 2.0);
					}
					spans[i] = mid;
				}
				float N     [msize + 1][2];
				float left  [msize + 1][2];
				float right [msize + 1][2];
				N[0][0] = N[0][1] = 1.0;
				[loop] for (int h = 0; h < 2; h++)
				{
					float saved = 0.0, temp = 0.0;
					[loop] for (int j = 1; j <= degree[h]; j++)
					{
						left[j][h] = (uv[h] - knots[spans[h] + 1 - j][h]);
						right[j][h] = knots[spans[h] + j][h] - uv[h];
						saved = 0.0;
						[loop] for (int r = 0; r < j; r++)
						{
							temp = N[r][h] / (right[r + 1][h] + left[j - r][h]);
							N[r][h] = saved + right[r + 1][h] * temp;
							saved = left[j - r][h] * temp;
						}
						N[j][h] = saved;
					}
				}
				for (int m = 0; m <= degree[1]; m++)
				{
					float4 t = 0;
					for (int k = 0; k <= degree[0]; k++) t += cps[spans[0] - degree[0] + k][spans[1] - degree[1] + m] * N[k][0];
					p += t * N[m][1];
				}
				return (p.w != 0) ? p.xyz / p.w : p.xyz;
			}

			float3 NurbsSurfaceNormal (float4 cps[4][7], int2 cpsDim, float knots[11][2], int2 knotsDim, float2 uv)
			{
				for (int x = 0; x < cpsDim[0]; x++) for (int y = 0; y < cpsDim[1]; y++) cps[x][y].xyz *= cps[x][y].w;
				const int order = 1; // order of the derivative
				const int2 degree = int2(3, 3); // surface degrees
				#define msize max(degree.x, degree.y)
				int2 spans = int2(0, 0);
				[unroll(2)] for (int i = 0; i < 2; i++) // find spans
				{
					int n = knotsDim[i] - degree[i] - 2;
					if (uv[i] == (knots[n + 1][i])) spans[i] = n;
					int low = degree[i];
					int high = n + 1;
					int mid = (int)floor((low + high) / 2.0);
					[unroll(16)] while (uv[i] < knots[mid][i] || uv[i] >= knots[mid + 1][i])
					{
						if (uv[i] < knots[mid][i])
							high = mid;
						else
							low = mid;
						mid = (int)floor((low + high) / 2.0);
					}
					spans[i] = mid;
				}
				float basis[order + 1][msize + 1][2];
				float left[msize + 1][2];
				float right[msize + 1][2];
				float ndu[msize + 1][msize + 1][2];
				ndu[0][0][0] = ndu[0][0][1] = 1.0;
				[unroll(2)] for (int q = 0; q < 2; q++) // derivatives of the basis functions
				{
					[loop] for (int j = 1; j <= degree[q]; j++)
					{
						left[j][q] = uv[q] - knots[spans[q] + 1 - j][q];
						right[j][q] = knots[spans[q] + j][q] - uv[q];
						float saved = 0.0;
						[loop] for (int r = 0; r < j; r++)
						{
							ndu[j][r][q] = right[r + 1][q] + left[j - r][q];
							float temp = ndu[r][j - 1][q] / ndu[j][r][q];
							ndu[r][j][q] = saved + right[r + 1][q] * temp;
							saved = left[j - r][q] * temp;
						}
						ndu[j][j][q] = saved;
					}
					[loop] for (int m = 0; m <= degree[q]; m++) basis[0][m][q] = ndu[m][degree[q]][q];
					float a[2][msize + 1][2];
					for (int r = 0; r <= degree[q]; r++)
					{
						int s1 = 0;
						int s2 = 1;
						a[0][0][q] = 1.0;
						[unroll(order)] for (int k = 1; k <= order; k++)
						{
							float d = 0.0;
							int rk = r - k;
							int pk = degree[q] - k;
							int j1 = 0;
							int j2 = 0;
							if (r >= k)
							{
								a[s2][0][q] = a[s1][0][q] / ndu[pk + 1][rk][q];
								d = a[s2][0][q] * ndu[rk][pk][q];
							}
							j1 = (rk >= -1) ? 1 : -rk;
							j2 = (r - 1 <= pk) ? k - 1 : degree[q] - r;
							[unroll(order)] for (int j = j1; j <= j2; j++)
							{
								a[s2][j][q] = (a[s1][j][q] - a[s1][j - 1][q]) / ndu[pk + 1][rk + j][q];
								d += a[s2][j][q] * ndu[rk + j][pk][q];
							}
							if (r <= pk)
							{
								a[s2][k][q] = -a[s1][k - 1][q] / ndu[pk + 1][r][q];
								d += a[s2][k][q] * ndu[r][pk][q];
							}
							basis[k][r][q] = d;
							int s3 = s1;
							s1 = s2;
							s2 = s3;
						}
					}
					float f = degree[q];
					[unroll(order)] for (int k = 1; k <= order; k++)
					{
						for (int h = 0; h <= degree[q]; h++) basis[k][h][q] *= f;
						f *= degree[q] - k;
					}
				}
				float4 derivatives[order + 1][order + 1] = {{0..xxxx, 0..xxxx}, {0..xxxx, 0..xxxx}};
				int du = min(order, degree[0]);
				int dv = min(order, degree[1]);
				float4 temp[degree[1] + 1];
				[unroll(4)] for (int w = 0; w <= du; w++) // derivatives of a B-spline surface
				{
					[unroll(4)] for (int s = 0; s <= degree[1]; s++)
					{
						temp[s] = (float4) 0;
						[unroll(4)] for (int r = 0; r <= degree[0]; r++)
						{
							float4 pw = cps[spans[0] - degree[0] + r] [spans[1] - degree[1] + s];
							temp[s] += pw * basis[w][r][0];
						}
					}
					int dd = min(order - w, dv);
					[unroll(4)] for (int l = 0; l <= dd; l++)
					{
						[loop] for (int s = 0; s <= degree[1]; s++) derivatives[w][l] += temp[s] * basis[l][s][1];
					}
				}
				float3 SKL[order + 1][order + 1]; 
				int BIN[4] = {1,1,1,1}; // binomial coefficients
				[unroll(4)] for (int k = 0; k < (order + 1); ++k) // derivatives of a NURBS surface
				{
					[unroll(4)] for (int l = 0; l < order - k + 1; ++l)
					{
						float3 v = derivatives[k][l].xyz;
						[unroll(4)] for (int z = 1; z < l + 1; ++z)
						{
							if (z > l) continue;
							[unroll(4)] for (int a = 1; a <= z; ++a) BIN[0] *= (l + 1 - a) / a;
							v -= SKL[k][l - z] * derivatives[0][z].w * BIN[0];
						}
						[unroll(4)] for (int i = 1; i < k + 1; ++i)
						{
							if (i > k) 
								BIN[1] = 0;
							else
								[unroll(4)] for (int b = 1; b <= i; ++b) BIN[1] *= (k + 1 - b) / b;
							v -= SKL[k - i][l] * derivatives[i][0].w * BIN[1];
							float3 tmp = (float3) 0;
							[unroll(4)] for (int j = 1; j < l + 1; ++j)
							{
								if (j > l) continue;
								[unroll(4)] for (int c = 1; c <= j; ++c) BIN[2] *= (l + 1 - c) / c;
								tmp -= SKL[k - 1][l - j] * derivatives[i][j].w * BIN[2];
							}
							if (i > k) continue;
							[unroll(4)] for (int d = 1; d <= i; ++d) BIN[3] *= (k + 1 - d) / d;
							v -= tmp * BIN[3];
						}
						SKL[k][l] = v / derivatives[0][0].w;
					}
				}
				return normalize(cross(SKL[1][0], SKL[0][1]));
			}
 
			float4 VSMain (uint vertexId : SV_VertexID, out float3 normal : NORMAL, out float2 texcoord : TEXCOORD0) : SV_POSITION
			{
				int instance = int(floor(vertexId / 6.0));
				float x = sign(Mod(float(vertexId), 2.0));
				float y = sign(Mod(126.0, Mod(float(vertexId), 6.0) + 6.0));
				float u = (float(instance / _TessellationFactor) + x) / float(_TessellationFactor);
				float v = (Mod(float(instance), float(_TessellationFactor)) + y) / float(_TessellationFactor);
				float2 uv = float2(u,v);
				float3 localPos = NurbsSurface (ControlPoints, int2(4, 7), KnotVectors, int2(8, 11), uv);
				normal = (_NormalsMode > 0) ? localPos : NurbsSurfaceNormal (ControlPoints, int2(4, 7), KnotVectors, int2(8, 11), uv);
				texcoord = uv;
				return UnityObjectToClipPos(float4(localPos, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 normal : NORMAL, float2 texcoord : TEXCOORD0) : SV_Target
			{
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normalDir = (_NormalsMode > 0) ? normalize(cross(ddy(normal), ddx(normal))) : normalize(normal);
				float diffuse = max(dot(lightDir, normalDir), 0.1);
				float pattern = Checkerboard(texcoord * _TessellationFactor);
				return float4(pattern.xxx * diffuse, 1.0);
			}
			ENDCG
		}
	}
}