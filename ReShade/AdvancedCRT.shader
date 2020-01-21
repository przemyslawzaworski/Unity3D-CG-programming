// Original source: https://github.com/crosire/reshade-shaders/blob/master/Shaders/CRT.fx
Shader "Reshade/AdvancedCRT"
{
	Subshader
	{	
		CGINCLUDE
		#pragma vertex PostProcessVS
		#pragma target 5.0

		sampler2D BackBuffer;

		static const float2 ASPECT_RATIO = float2(1.0, _ScreenParams.x / _ScreenParams.y);
		static const float2 BUFFER_PIXEL_SIZE = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
		static const float2 BUFFER_SCREEN_SIZE = float2(_ScreenParams.x, _ScreenParams.y);

		float Amount, Resolution, Gamma, MonitorGamma, Brightness;	
		int ScanlineIntensity; bool ScanlineGaussian, Curvature, Oversample;
		float CurvatureRadius, CornerSize, ViewerDistance, Overscan;
		float4 Angle;
		
		//#define LINEAR_PROCESSING
		#define CeeJay_aspect float2(1.0, 0.75)
		#define sinangle sin(Angle.xy)
		#define cosangle cos(Angle.xy)
		#define stretch maxscale()
		#define FIX(c) max(abs(c), 1e-5);
		#define PI 3.1415927
		#define coone 1.0 / rubyTextureSize
		#define mod_factor tex.x * rubyTextureSize.x * rubyOutputSize.x / rubyInputSize.x

		#ifdef LINEAR_PROCESSING
			#define TEX2D(c) pow(tex2D(BackBuffer, (c)), Gamma)
		#else
			#define TEX2D(c) tex2D(BackBuffer, (c))
		#endif

		float intersect(float2 xy)
		{
			float A = dot(xy,xy) + (ViewerDistance * ViewerDistance);
			float B = 2.0 * (CurvatureRadius * (dot(xy, sinangle) - ViewerDistance * cosangle.x * cosangle.y) - ViewerDistance * ViewerDistance);
			float C = ViewerDistance * ViewerDistance + 2.0 * CurvatureRadius * ViewerDistance * cosangle.x * cosangle.y;
			return (-B - sqrt(B * B -4.0 * A * C)) / (2.0 * A);
		}

		float2 bkwtrans(float2 xy)
		{
			float c = intersect(xy);
			float2 _point = float2(c, c) * xy;
			_point -= float2(-CurvatureRadius, -CurvatureRadius) * sinangle;
			_point /= float2(CurvatureRadius, CurvatureRadius);
			float2 tang = sinangle / cosangle;
			float2 poc = _point / cosangle;
			float A = dot(tang, tang) + 1.0;
			float B = -2.0 * dot(poc, tang);
			float C = dot(poc, poc) - 1.0;
			float a = (-B + sqrt(B * B -4.0 * A * C)) / (2.0 * A);
			float2 uv = (_point - a * sinangle) / cosangle;
			float r = CurvatureRadius * acos(a);
			return uv * r / sin(r / CurvatureRadius);
		}
		
		float2 fwtrans(float2 uv)
		{
			float r = FIX(sqrt(dot(uv, uv)));
			uv *= sin(r / CurvatureRadius) / r;
			float x = 1.0 - cos(r / CurvatureRadius);
			float D = ViewerDistance / CurvatureRadius + x * cosangle.x * cosangle.y + dot(uv, sinangle);
			return ViewerDistance * (uv * cosangle - x * sinangle) / D;
		}

		float3 maxscale()
		{
			float2 c = bkwtrans(-CurvatureRadius * sinangle / (1.0 + CurvatureRadius / ViewerDistance * cosangle.x * cosangle.y));
			float2 a = float2(0.5, 0.5) * CeeJay_aspect;
			float2 lo = float2(fwtrans(float2(-a.x, c.y)).x, fwtrans(float2(c.x,-a.y)).y) / CeeJay_aspect;
			float2 hi = float2(fwtrans(float2(+a.x, c.y)).x, fwtrans(float2(c.x, +a.y)).y) / CeeJay_aspect;
			return float3((hi + lo) * CeeJay_aspect * 0.5, max(hi.x - lo.x, hi.y - lo.y));
		}

		float2 transform(float2 coord, float2 textureSize, float2 inputSize)
		{
			coord *= textureSize / inputSize;
			coord = (coord - 0.5) * CeeJay_aspect * stretch.z + stretch.xy;
			return (bkwtrans(coord) / float2(Overscan, Overscan) / CeeJay_aspect + 0.5) * inputSize / textureSize;
		}

		float corner(float2 coord, float2 textureSize, float2 inputSize)
		{
			coord *= textureSize / inputSize;
			coord = (coord - 0.5) * float2(Overscan, Overscan) + 0.5;
			coord = min(coord, 1.0 - coord) * CeeJay_aspect;
			float2 cdist = float2(CornerSize, CornerSize);
			coord = (cdist - min(coord, cdist));
			float dist = sqrt(dot(coord, coord));
			return clamp((cdist.x-dist) * 1000.0, 0.0, 1.0);
		}

		float4 scanlineWeights(float distance, float4 color)
		{
			if (!ScanlineGaussian)
			{
				float4 wid = 0.3 + 0.1 * pow(abs(color), 3.0);
				float4 weights = float4(distance / wid);
				return 0.4 * exp(-weights * weights) / wid;
			}
			else
			{
				float4 wid = 2.0 * pow(abs(color), 4.0) + 2.0;
				float4 weights = (distance / 0.3).xxxx;
				return 1.4 * exp(-pow(abs(weights * rsqrt(0.5 * wid)), abs(wid))) / (0.2 * wid + 0.6);
			}
		}
		
		void PostProcessVS (inout float4 vertex:POSITION, inout float2 tex:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}		
				
		ENDCG
		
		Pass
		{
			CGPROGRAM
			#pragma fragment AdvancedCRTPass
			
			float4 AdvancedCRTPass (float4 vertex:SV_POSITION, float2 tex:TEXCOORD0) : SV_Target0
			{
				float  Input_ratio = ceil(256 * Resolution);
				float2 Resolution = float2(Input_ratio, Input_ratio);
				float2 rubyTextureSize = Resolution;
				float2 rubyInputSize = Resolution;
				float2 rubyOutputSize = BUFFER_SCREEN_SIZE;
				float2 orig_xy = Curvature ? transform(tex, rubyTextureSize, rubyInputSize) : tex;
				float cval = corner(orig_xy, rubyTextureSize, rubyInputSize);
				float2 ratio_scale = orig_xy * rubyTextureSize - 0.5;
				float filter = fwidth(ratio_scale.y);
				float2 uv_ratio = frac(ratio_scale);
				float2 xy = (floor(ratio_scale) + 0.5) / rubyTextureSize;
				float4 coeffs = PI * float4(1.0 + uv_ratio.x, uv_ratio.x, 1.0 - uv_ratio.x, 2.0 - uv_ratio.x);
				coeffs = FIX(coeffs);
				coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);
				coeffs /= dot(coeffs, 1.0);
				float4 col  = clamp(mul(coeffs, float4x4(
					TEX2D(xy + float2(-coone.x, 0.0)),
					TEX2D(xy),
					TEX2D(xy + float2(coone.x, 0.0)),
					TEX2D(xy + float2(2.0 * coone.x, 0.0)))),
					0.0, 1.0);
				float4 col2 = clamp(mul(coeffs, float4x4(
					TEX2D(xy + float2(-coone.x, coone.y)),
					TEX2D(xy + float2(0.0, coone.y)),
					TEX2D(xy + coone),
					TEX2D(xy + float2(2.0 * coone.x, coone.y)))),
					0.0, 1.0);

				#ifndef LINEAR_PROCESSING
					col  = pow(abs(col) , Gamma);
					col2 = pow(abs(col2), Gamma);
				#endif

				float4 weights  = scanlineWeights(uv_ratio.y, col);
				float4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);
				if (Oversample)
				{
					uv_ratio.y = uv_ratio.y + 1.0 / 3.0 * filter;
					weights = (weights + scanlineWeights(uv_ratio.y, col)) / 3.0;
					weights2 = (weights2 + scanlineWeights(abs(1.0 - uv_ratio.y), col2)) / 3.0;
					uv_ratio.y = uv_ratio.y - 2.0 / 3.0 * filter;
					weights = weights + scanlineWeights(abs(uv_ratio.y), col) / 3.0;
					weights2 = weights2 + scanlineWeights(abs(1.0 - uv_ratio.y), col2) / 3.0;
				}
				float3 mul_res = (col * weights + col2 * weights2).rgb * cval.xxx;
				float3 dotMaskWeights = lerp(float3(1.0, 0.7, 1.0), float3(0.7, 1.0, 0.7), floor(mod_factor % ScanlineIntensity));
				mul_res *= dotMaskWeights * float3(0.83, 0.83, 1.0) * Brightness;
				mul_res = pow(abs(mul_res), 1.0 / MonitorGamma);
				float3 color = TEX2D(orig_xy).rgb * cval.xxx;
				color = lerp(color, mul_res, Amount);
				return float4(saturate(color), 1.0);
			}
			ENDCG
		}
		
	}
}