// Author: Przemyslaw Zaworski
Shader "Paint URP"
{
	SubShader
	{
		Pass
		{
			ZTest Off
			ZWrite Off
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			float _BrushRadius, _BrushPower, _BrushMovement, _BrushForce, _BrushEnd;
			float4 _BrushCenter, _BrushColor, _RayOrigin, _LastBrushCenter;
			float4x4 _ModelMatrix;
			Texture2D _RenderTexture, _ColorTexture;
			SamplerState sampler_point_clamp;

			struct Attributes
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct Interpolators
			{
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 worldPos : WORLDPOS;
			};

			struct RenderTargets
			{
				float4 target0 : SV_Target0;
				float4 target1 : SV_Target1;
			};

			float Sphere(float3 p, float3 c, float r)
			{
				return length (p - c) - r;
			}

			float Line(float3 p, float3 a, float3 b, float r)
			{
				float3 pa = p - a, ba = b - a;
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return length(pa - ba * h) - r;
			}

			float Subtraction(float d1, float d2)
			{
				return max(-d1, d2);
			}

			Interpolators VSMain (Attributes attributes)
			{
				Interpolators interpolators;
				interpolators.worldPos = mul(_ModelMatrix, attributes.position).xyz;
				interpolators.normal = mul(_ModelMatrix, float4(attributes.normal, 0.0)).xyz;
				interpolators.uv = attributes.uv;
				float2 texcoord = attributes.uv;
				#if UNITY_UV_STARTS_AT_TOP
					texcoord.y = 1.0 - texcoord.y;
				#endif
				texcoord = texcoord * 2.0 - 1.0;
				interpolators.position = float4(texcoord, 0.0, 1.0);
				return interpolators;
			}

			RenderTargets PSMain (Interpolators interpolators)
			{
				RenderTargets renderTargets;
				float3 worldPos = interpolators.worldPos;
				float2 uv = interpolators.uv;
				float3 nd = normalize(interpolators.normal);
				float3 rd = normalize(-(_BrushCenter.xyz - _RayOrigin.xyz));
				bool isVisible = dot(rd, nd) >= 0.0;
				float capsule = Line(worldPos, _LastBrushCenter.xyz, _BrushCenter.xyz, _BrushRadius);
				float sphere = Sphere(worldPos, _BrushCenter.xyz, _BrushRadius);
				float paintTexture = _RenderTexture.Sample(sampler_point_clamp, uv).r;
				float3 colorTexture = _ColorTexture.Sample(sampler_point_clamp, uv).rgb;
				bool isMove = _BrushMovement > 0.5;
				float sdf = isMove ? Subtraction(sphere, capsule) : sphere;
				float opacity = isMove ? _BrushForce : _BrushPower;
				float end = (_BrushEnd > 0.5) ? step(sphere, 0.0) * _BrushForce : 0.0;
				float weight = step(isVisible ? sdf : 1e6, 0.0) * opacity + end;
				float brush = step(isVisible ? sphere : 1e6, 0.0) * _BrushForce;
				float accumulation = min(weight + paintTexture, 1.0);
				float3 color = lerp(colorTexture, _BrushColor.xyz, weight);
				renderTargets.target0 = float4(accumulation, brush, 0.0, 0.0);
				renderTargets.target1 = float4(color, 0.0);
				return renderTargets;
			}
			ENDHLSL
		}
	}
}