Shader "Bezier Surface"
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

			static float3 ControlPoints[4][4] = 
			{
				{float3(00.0, 00.0, 00.0), float3(10.0, 00.0, 00.0), float3(20.0, 00.0, 00.0),float3(30.0, 00.0, 00.0)},
				{float3(00.0, 00.0, 10.0), float3(10.0, 10.0, 10.0), float3(20.0, 10.0, 10.0),float3(30.0, 00.0, 10.0)},
				{float3(00.0, 00.0, 20.0), float3(10.0, 10.0, 20.0), float3(20.0, 10.0, 20.0),float3(30.0, 00.0, 20.0)},
				{float3(00.0, 00.0, 30.0), float3(10.0, 00.0, 30.0), float3(20.0, 00.0, 30.0),float3(30.0, 00.0, 30.0)}
			};

			// https://en.wikipedia.org/wiki/B%C3%A9zier_curve
			float3 BezierCurve (float3 a, float3 b, float3 c, float3 d, float t)
			{
				float x = a.x * (1.0 - t) * (1.0 - t) * (1.0 - t) + 3.0 * b.x * t * (1.0 - t) * (1.0 - t) + 3.0 * c.x * t * t * (1.0 - t) + d.x * t * t * t;
				float y = a.y * (1.0 - t) * (1.0 - t) * (1.0 - t) + 3.0 * b.y * t * (1.0 - t) * (1.0 - t) + 3.0 * c.y * t * t * (1.0 - t) + d.y * t * t * t;
				float z = a.z * (1.0 - t) * (1.0 - t) * (1.0 - t) + 3.0 * b.z * t * (1.0 - t) * (1.0 - t) + 3.0 * c.z * t * t * (1.0 - t) + d.z * t * t * t;
				return float3 (x, y, z);
			}

			float3 BezierPatch (float3 cp[4][4], float u, float v)
			{
				float3 a = BezierCurve (cp[0][0], cp[0][1], cp[0][2], cp[0][3], u);
				float3 b = BezierCurve (cp[1][0], cp[1][1], cp[1][2], cp[1][3], u);
				float3 c = BezierCurve (cp[2][0], cp[2][1], cp[2][2], cp[2][3], u);
				float3 d = BezierCurve (cp[3][0], cp[3][1], cp[3][2], cp[3][3], u);
				return BezierCurve(a, b, c, d, v);
			}

			float3 BezierPatchNormal (float3 cp[4][4], float u, float v)
			{
				float3 a = BezierCurve (cp[0][0], cp[0][1], cp[0][2], cp[0][3], u);
				float3 b = BezierCurve (cp[1][0], cp[1][1], cp[1][2], cp[1][3], u);
				float3 c = BezierCurve (cp[2][0], cp[2][1], cp[2][2], cp[2][3], u);
				float3 d = BezierCurve (cp[3][0], cp[3][1], cp[3][2], cp[3][3], u);
				float3 dv = -3.0 * (1.0 - v) * (1.0 - v) * a + (3.0 * (1.0 - v) * (1.0 - v) - 6.0 * v * (1.0 - v)) * b + (6.0 * v * (1.0 - v) - 3.0 * v * v) * c + 3.0 * v * v * d;
				float3 e = BezierCurve (cp[0][0], cp[1][0], cp[2][0], cp[3][0], v);
				float3 f = BezierCurve (cp[0][1], cp[1][1], cp[2][1], cp[3][1], v);
				float3 g = BezierCurve (cp[0][2], cp[1][2], cp[2][2], cp[3][2], v);
				float3 h = BezierCurve (cp[0][3], cp[1][3], cp[2][3], cp[3][3], v);	
				float3 du = -3.0 * (1.0 - u) * (1.0 - u) * e + (3.0 * (1.0 - u) * (1.0 - u) - 6.0 * u * (1.0 - u)) * f + (6.0 * u * (1.0 - u) - 3.0 * u * u) * g + 3.0 * u * u * h;
				return normalize(cross(dv, du));
			}

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

			void Animation()
			{
				ControlPoints[1][1].y = 30.0 * cos(_Time.g * 0.5);
				ControlPoints[2][2].y = 20.0 * sin(_Time.g * 0.7);
				ControlPoints[1][2].y = 30.0 * sin(_Time.g * 0.9);
				ControlPoints[2][1].y = 40.0 * cos(_Time.g * 0.6);
			}

			float4 VSMain (uint vertexId : SV_VertexID, out float3 normal : NORMAL, out float2 texcoord : TEXCOORD0) : SV_POSITION
			{
				Animation();
				int instance = int(floor(vertexId / 6.0));
				float x = sign(Mod(float(vertexId), 2.0));
				float y = sign(Mod(126.0, Mod(float(vertexId), 6.0) + 6.0));
				float u = (float(instance / _TessellationFactor) + x) / float(_TessellationFactor);
				float v = (Mod(float(instance), float(_TessellationFactor)) + y) / float(_TessellationFactor);
				float3 localPos = BezierPatch (ControlPoints, u, v);
				normal = BezierPatchNormal (ControlPoints, u, v);
				texcoord = float2(u, v);
				return UnityObjectToClipPos(float4(localPos, 1.0));
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 normal : NORMAL, float2 texcoord : TEXCOORD0) : SV_Target
			{
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normalDir = normalize(normal);
				float diffuse = max(dot(lightDir, normalDir), 0.2);
				float pattern = Checkerboard(texcoord * _TessellationFactor);
				return float4(diffuse.xxx * (float3)(pattern), 1.0);
			}
			ENDCG
		}
	}
}