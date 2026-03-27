// ﻿Usage: Windows / Rendering / Lighting Settings -> Environment / Skybox Material
// Reference: https://www.shadertoy.com/view/scSGDV
Shader "Volumetric Overcast Clouds"
{
	Subshader
	{
		Tags { "RenderType" = "Background" }
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0
			
			struct Ray 
			{
				float3 origin;
				float3 direction;
			};

			struct Volume
			{
				float3 origin;
				float3 position; 
				float height;
				float absorption;
				float transmittance; 
				float3 color;
				float alpha;
			}; 

			float4 Mod289(float4 x) 
			{
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			float4 Permute(float4 x) 
			{
				return Mod289(((x * 34.0) + 1.0) * x);
			}

			float SimplexNoise(float3 v)
			{ 
				const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
				const float4 D = float4(0.0, 0.5, 1.0, 2.0);
				float3 i = floor(v + dot(v, C.yyy));
				float3 x0 = v - i + dot(i, C.xxx) ;
				float3 g = step(x0.yzx, x0.xyz);
				float3 l = 1.0 - g;
				float3 i1 = min(g.xyz, l.zxy);
				float3 i2 = max(g.xyz, l.zxy);
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - D.yyy;     
				i = i - floor(i * (1.0 / 289.0)) * 289.0;
				float4 pz = Permute(i.z + float4(0.0, i1.z, i2.z, 1.0));
				float4 py = Permute(pz + i.y + float4(0.0, i1.y, i2.y, 1.0));
				float4 p = Permute(py + i.x + float4(0.0, i1.x, i2.x, 1.0));    
				float n_ = 0.142857142857; 
				float3 ns = n_ * D.wyz - D.xzx;
				float4 j = p - 49.0 * floor(p * ns.z * ns.z);  
				float4 x_ = floor(j * ns.z);
				float4 y_ = floor(j - 7.0 * x_ ); 
				float4 x = x_ *ns.x + ns.yyyy;
				float4 y = y_ *ns.x + ns.yyyy;
				float4 h = 1.0 - abs(x) - abs(y);
				float4 b0 = float4(x.xy, y.xy);
				float4 b1 = float4(x.zw, y.zw);
				float4 s0 = floor(b0) * 2.0 + 1.0;
				float4 s1 = floor(b1) * 2.0 + 1.0;
				float4 sh = -step(h, float4(0, 0, 0, 0));
				float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
				float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
				float3 p0 = float3(a0.xy,h.x);
				float3 p1 = float3(a0.zw,h.y);
				float3 p2 = float3(a1.xy,h.z);
				float3 p3 = float3(a1.zw,h.w);
				float4 norm = 1.79284291400159 - 0.85373472095314 * (float4(dot(p0,p0),dot(p1,p1),dot(p2, p2),dot(p3,p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;
				float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
				m = m * m;
				return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
			}

			float FractalBrownianMotion(float3 position, float lacunarity, float amplitude, float gain) 
			{   
				float value = 0.0; 
				for (int i = 0; i < 5; i++)
				{
					value += abs(SimplexNoise(position)) * amplitude; 
					position *= lacunarity; 
					amplitude *= gain; 
				}
				return value; 
			}

			float3 SkyColor(float3 rayDirection)
			{
				float3 sunColor = float3(1.0, 0.7, 0.55);
				float3 sunDirection = normalize(float3(0, 0, -1));
				float sunAmount = max(dot(rayDirection, sunDirection), 0.0);
				float3 sky = lerp(float3(0.0, 0.1, 0.4), float3(0.3, 0.6, 0.8), 1.0 - rayDirection.y);
				sky += sunColor * min(pow(sunAmount, 1500.0) * 5.0, 1.0);
				sky += sunColor * min(pow(sunAmount, 10.0) * 0.6, 1.0);
				return sky;
			}

			float CloudDensity(float3 rayPosition)
			{
				float3 wind = float3(0, 0, -_Time.g * 0.05);
				float3 position = rayPosition * 0.001 + wind;
				float density = FractalBrownianMotion(position * 2.032, 2.6434, 0.5, 0.5);
				float coverage = 0.3125;
				float softness = 0.0350;
				density *= smoothstep (coverage, coverage + softness, density);
				return density;
			}

			float4 Raymarching(Ray ray)
			{
				const int maxSteps = 50;
				const float thickness = 90.0;
				const float stepSize = thickness / float(maxSteps);
				float3 rayProjection = ray.direction / ray.direction.y;
				float3 rayStep = rayProjection * stepSize;
				float alpha = dot(ray.direction, float3(0, 1, 0));
				float3 origin = ray.origin + rayProjection * 100.0;
				Volume cloud;
				cloud.origin = origin;
				cloud.position = origin;
				cloud.height = 0.0;
				cloud.absorption = 1.0;
				cloud.transmittance = 1.0;
				cloud.color = float3(0.0, 0.0, 0.0);
				cloud.alpha = 0.0;			
				for (int i = 0; i < maxSteps; i++) 
				{
					cloud.height = (cloud.position.y - cloud.origin.y) / thickness;
					float density = CloudDensity(cloud.position);
					float stepTransmittance = exp(-cloud.absorption * density * stepSize);
					cloud.transmittance *= exp(-cloud.absorption * density * stepSize);
					cloud.color += cloud.transmittance * exp(cloud.height) / 1.95 * density * stepSize;
					cloud.alpha += (1.0 - stepTransmittance) * (1.0 - cloud.alpha);
					cloud.position += rayStep;
					if (cloud.alpha > 0.999) break;
				}
				return float4(cloud.color, cloud.alpha * smoothstep(0.0, 0.2, alpha));
			}

			float3 FinalColor(Ray ray)
			{
				float3 sky = SkyColor(ray.direction);
				if (dot(ray.direction, float3(0, 1, 0)) < 0.05) return sky;
				float4 clouds = Raymarching(ray);
				return lerp(sky, clouds.rgb, clouds.a);
			}

			float4 VSMain(float4 vertex : POSITION, out float3 worldPos : TEXCOORD1) : SV_POSITION
			{
				worldPos = mul (unity_ObjectToWorld, vertex);
				return UnityObjectToClipPos (vertex);
			}

			float4 PSMain(float4 vertex : SV_POSITION, float3 worldPos : TEXCOORD1) : SV_TARGET
			{
				Ray ray;
				ray.origin = _WorldSpaceCameraPos.xyz;
				ray.direction = normalize(worldPos - _WorldSpaceCameraPos.xyz);
				return float4(FinalColor(ray), 1.0);
			}
			ENDCG
		}
	}
}