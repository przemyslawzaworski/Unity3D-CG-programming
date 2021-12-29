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

			uint _TessellationFactor;

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
 
			float4 VSMain (uint vertexId : SV_VertexID, out float3 normal : NORMAL, out float2 texcoord : TEXCOORD0) : SV_POSITION
			{
				int instance = int(floor(vertexId / 6.0));
				float x = sign(Mod(float(vertexId), 2.0));
				float y = sign(Mod(126.0, Mod(float(vertexId), 6.0) + 6.0));
				float u = (float(instance / _TessellationFactor) + x) / float(_TessellationFactor);
				float v = (Mod(float(instance), float(_TessellationFactor)) + y) / float(_TessellationFactor);
				float2 uv = float2(u,v);
				float3 localPos = NurbsSurface (ControlPoints, int2(4, 7), KnotVectors, int2(8, 11), uv);
				normal = normalize(localPos);
				texcoord = uv;
				return UnityObjectToClipPos(float4(localPos, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 normal : NORMAL, float2 texcoord : TEXCOORD0) : SV_Target
			{
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normalDir = normalize(normal);
				float diffuse = max(dot(lightDir, normalDir), 0.2);
				float pattern = Checkerboard(texcoord * _TessellationFactor);
				return float4(pattern.xxx * diffuse, 1.0);
			}
			ENDCG
		}
	}
}