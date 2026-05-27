Shader "Pencil Effect"
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

			Texture2D _MainTex;
			SamplerState sampler_linear_clamp;
			float _InvertY;
			float _ScaleFactor;

			float Hash(float2 p)
			{
				p = frac(p * float2(123.34, 456.21));
				p += dot(p, p + 45.32);
				return frac(p.x * p.y);
			}

			float Noise(float2 p)
			{
				float2 i = floor(p);
				float2 f = frac(p);
				f = f * f * (3.0 - 2.0 * f);
				float a = Hash(i);
				float b = Hash(i + float2(1.0, 0.0));
				float c = Hash(i + float2(0.0, 1.0));
				float d = Hash(i + float2(1.0, 1.0));
				return lerp(lerp(a, b, f.x),lerp(c, d, f.x),f.y);
			}

			float4 Random(float2 p)
			{
				float noise = Noise(p);
				return float4((float3)noise, 1.0);
			}

			float4 SampleColor(float2 pos, float2 randomOffset, float ramp, float randomScale, float scaleFactor)
			{
				float4 offset = (Random((pos + randomOffset) * 0.05 * randomScale / scaleFactor) - 0.5) * 10.0 * ramp;
				float2 uv = (pos + offset.xy * scaleFactor) / _ScreenParams.xy;
				return _MainTex.SampleLevel(sampler_linear_clamp, uv, 0.0);
			}

			float Luminance(float2 pos, float2 randomOffset, float ramp, float randomScale, float scaleFactor)
			{
				float3 color = SampleColor(pos, randomOffset, ramp, randomScale, scaleFactor).xyz;
				return clamp(dot(color, (float3)(0.333)), 0.0, 1.0);
			}

			float2 Gradient(float2 pos, float eps, float2 randomOffset, float ramp, float randomScale, float scaleFactor)
			{
				float2 d = float2(eps, 0.0);
				float gx = Luminance(pos + d.xy, randomOffset, ramp, randomScale, scaleFactor);
				gx -= Luminance(pos - d.xy, randomOffset, ramp, randomScale, scaleFactor);
				float gy = Luminance(pos + d.yx, randomOffset, ramp, randomScale, scaleFactor);
				gy -= Luminance(pos - d.yx, randomOffset, ramp, randomScale, scaleFactor);
				return float2(gx, gy) / (eps * 2.0);
			}

			float EdgeContribution(float2 fragCoord, float fi, int layerCount, float scaleFactor)
			{
				float threshold = 0.03 + 0.25 * fi;
				float width = threshold * 2.0;
				float brightness = 0.0;
				float ramp = 0.15 * pow(1.3, fi * 5.0);
				float randomScale = 1.7 * pow(1.3, -fi * 5.0);
				float grad = length(Gradient(fragCoord, 0.4 * scaleFactor, float2(0.0, 0.0), ramp, randomScale, scaleFactor));
				grad *= scaleFactor;
				brightness += 0.6 * (0.5 + fi) * smoothstep(threshold - width * 0.5,threshold + width * 0.5, grad); 
				ramp = 0.3 * pow(1.3, fi * 5.0);
				randomScale = 10.7 * pow(1.3, -fi * 5.0);
				grad = length(Gradient(fragCoord, 0.4 * scaleFactor, float2(0.0, 0.0), ramp, randomScale, scaleFactor));
				grad *= scaleFactor;
				brightness += 0.4 * (0.2 + fi) * smoothstep(threshold - width * 0.5,threshold + width * 0.5, grad);
				return brightness;
			}

			float HatchLayer(float2 fragCoord, int layerIndex, float scaleFactor, float4 randomDelta, inout float hatchMax)
			{
				float2 position = fragCoord + 1.5 * scaleFactor * (Random(fragCoord * 0.02).xy - 0.5);
				float brightness = Luminance(position, float2(0.0, 0.0), 0.0, 1.0, scaleFactor) * 1.7;
				float angle = -0.5 - 0.08 * float(layerIndex * layerIndex);
				float2 basis = cos(angle - float2(0.0, 1.6));
				float2x2 rotation = float2x2(basis, basis.yx * float2(-1.0, 1.0));
				float2 hatchUv =  mul(rotation, fragCoord) / sqrt(scaleFactor) * float2(0.05, 1.0) * 1.3;
				float4 randomHatch = pow(Random(hatchUv + float2(sin(hatchUv.y + _Time.y * 5.0), 0.0)), (float4)(1.0));
				float hatch = 1.0 - smoothstep(0.5, 1.5, randomHatch.x + brightness) - 0.3 * abs(randomDelta.z);
				hatchMax = max(hatchMax, hatch);
				return hatch;
			}

			float4 PencilEffect(float2 fragCoord)
			{
				float scaleFactor = _ScaleFactor;
				float4 randomBase = Random(fragCoord * 1.2 / sqrt(scaleFactor));    
				float4 randomDelta = randomBase - Random(fragCoord * 1.2 / sqrt(scaleFactor) + float2(1.0, -1.0) * 1.5);
				float edgeBrightness = 0.0;
				int edgeLayers = 3;
				for (int j = 0; j < edgeLayers; j++)
				{
					float fi = float(j) / float(edgeLayers - 1);
					edgeBrightness += EdgeContribution(fragCoord, fi, edgeLayers, scaleFactor);
				}
				float3 color = (float3)1.0 - 0.7 * edgeBrightness * (0.5 + 0.5 * randomBase.z) * 3.0 / float(edgeLayers);
				color = clamp(color, 0.0, 1.0);
				const int hatchLayers = 5;
				float hatchAccum = 0.0;
				float hatchMax = 0.0;
				float hatchCount = 0.0;
				for (int i = 0; i < hatchLayers; i++)
				{
					float hatch = HatchLayer(fragCoord, i, scaleFactor, randomDelta, hatchMax);
					hatchAccum += hatch;
					hatchCount += 1.0;
					float brightness = Luminance(fragCoord, float2(0.0, 0.0), 0.0, 1.0, scaleFactor) * 1.7;
					if (float(i) > (1.0 - brightness) * float(hatchLayers) && i >= 2) break;
				}
				float hatchlerp = clamp(lerp(hatchAccum / hatchCount, hatchMax, 0.5), 0.0, 1.0);
				color *= 1.0 - hatchlerp;
				return float4(color, 1.0);
			}

			float4 VSMain (float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex : SV_POSITION) : SV_Target
			{
				float2 uv = float2(vertex.xy);
				if (_InvertY > 0.5) uv.y = _ScreenParams.y - uv.y - 1;
				return PencilEffect(uv);
			}
			ENDCG
		}
	}
}