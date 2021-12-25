Shader "Nurbs Curve"
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

			RWStructuredBuffer<float4> _ComputeBuffer : register(u1);
			float4 _ControlPoints[16]; // maximum 16 control points
			int _ControlPointsLength; // order
			float _Knots[20]; // maximum 20 knot vectors
			int _KnotsLength;
			int _VertexCount;
			float _CurveParameter;

			// L. Piegl, W. Tiller, "The NURBS Book", Springer Verlag, 1997
			// http://nurbscalculator.in/
			float3 NurbsCurve (float4 cps[16], int cpsLength, float knots[20], int knotsLength, float u)
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
				[unroll(12)]
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
				[loop]
				for (int j = 1; j <= degree; j++)
				{
					left[j] = (u - knots[index + 1 - j]);
					right[j] = knots[index + j] - u;
					saved = 0.0f;
					[loop]
					for (int r = 0; r < j; r++)
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

			float4 VSMain (uint vertexId : SV_VertexID, out float3 result : TEXCOORD0) : SV_POSITION
			{
				float u = float(vertexId) / float(_VertexCount - 1);
				float3 evaluation = NurbsCurve (_ControlPoints, _ControlPointsLength, _Knots, _KnotsLength, u);
				result = NurbsCurve (_ControlPoints, _ControlPointsLength, _Knots, _KnotsLength, _CurveParameter);
				return UnityObjectToClipPos(float4(evaluation, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 result : TEXCOORD0) : SV_Target
			{
				_ComputeBuffer[0] = float4(result, 1);
				return float4(0,0,1,1);
			}
			ENDCG
		}
	}
}