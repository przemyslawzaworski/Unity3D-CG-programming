Shader "ImageToSDFRenderer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			Texture2D _PaintMask;
			float4 _PaintMask_TexelSize;
			sampler2D _CameraDepthTexture, _MainTex;
			float4x4 _CameraInverseMatrix, _FrustumCorners;
			float4 _PainterRayOrigin, _PainterHitPoint, _PainterLastHitPoint;
			SamplerState sampler_point_clamp;

			struct Interpolators
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			float GetMask(float2 p, float scale, float radius)
			{
				p = p / radius;
				float2 uv = p + float2(0.5, 0.5);
				float r = _PaintMask.SampleLevel(sampler_point_clamp, uv, 0.0).r;
				return r / scale * radius;
			}

			float3x3 GetRotation(float3 ro, float3 ta, float cr)
			{
				float3 cw = normalize(ta-ro);
				float3 cp = float3(sin(cr), cos(cr),0.0);
				float3 cu = normalize( cross(cw,cp) );
				float3 cv = normalize( cross(cu,cw) );
				return float3x3( cu, cv, cw );
			}

			float Extrusion(float3 p, float h)
			{
				float d = GetMask(p.xy, _PaintMask_TexelSize.z, 1.0);
				float2 w = float2(d, abs(p.z) - h);
				return float(min(max(w.x, w.y), 0.0) + length(max(w, 0.0)));
			}

			float4 SDF(float3 p, float3 c, float h)
			{
				p = p - c;
				float3x3 m = GetRotation(c, _PainterRayOrigin, 0.0);
				p = mul(m, p);
				return Extrusion(p, h);
			}

			float Map(float3 p)
			{
				return SDF(p, _PainterHitPoint.xyz, 1.0);
			}

			float4 Raymarching(float3 ro, float3 rd, float s) 
			{
				float t = 0; 
				for (int i = 0; i < 64; i++) 
				{
					if (t >= s ) return float4(0,0,0,0);
					float3 p = ro + rd * t; 
					float d = Map(p);
					float3 color = (float3)(pow(1.0-float(i)/float(64.0),8.));
					if (d < 0.001) return float4(color * float3(1,0,0), 1.0);
					t += d;
				}
				return float4(0,0,0,0);
			}

			Interpolators VSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				Interpolators vs;
				half index = vertex.z;
				vertex.z = 0.1;
				vs.position = UnityObjectToClipPos(vertex);
				vs.uv = uv.xy;
				vs.ray = _FrustumCorners[(int)index].xyz;
				vs.ray /= abs(vs.ray.z);
				vs.ray = mul(_CameraInverseMatrix, vs.ray);
				return vs;
			}

			float4 PSMain (Interpolators ps) : SV_Target
			{
				float3 ro = _WorldSpaceCameraPos;
				float3 rd = normalize(ps.ray);
				float source = tex2D(_CameraDepthTexture, ps.uv).r;
				float depth = (1.0 / (_ZBufferParams.z * source + _ZBufferParams.w)) * length(ps.ray);
				float4 color = tex2D(_MainTex, ps.uv);
				float4 volume = Raymarching(ro, rd, depth);
				return lerp(color, volume, volume.w);
			}
			ENDCG
		}
	}
}