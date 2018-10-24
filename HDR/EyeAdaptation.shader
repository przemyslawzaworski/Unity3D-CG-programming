Shader "Hidden/Post FX/Eye Adaptation"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader			
			#pragma target 4.5
			#pragma multi_compile __ AUTO_KEY_VALUE

			#define HISTOGRAM_BINS          64
			#define HISTOGRAM_TEXELS        HISTOGRAM_BINS / 4
			#define HISTOGRAM_THREAD_X      16
			#define HISTOGRAM_THREAD_Y      16

			float4 _Params; 
			float2 _Speed; 
			float4 _ScaleOffsetRes; 
			float _ExposureCompensation;
			StructuredBuffer<uint> _Histogram;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			sampler2D _MainTex;

			float GetLuminanceFromHistogramBin(float bin, float2 scaleOffset)
			{
				return exp2((bin - scaleOffset.y) / scaleOffset.x);
			}
				
			float GetBinValue(uint index, float maxHistogramValue)
			{
				return float(_Histogram[index]) * maxHistogramValue;
			}

			float FindMaxHistogramValue()
			{
				uint maxValue = 0u;
				for (uint i = 0; i < HISTOGRAM_BINS; i++)
				{
				   uint h = _Histogram[i];
				   maxValue = max(maxValue, h);
				}
				return float(maxValue);
			}

			void FilterLuminance(uint i, float maxHistogramValue, inout float4 filter)
			{
				float binValue = GetBinValue(i, maxHistogramValue);
				float offset = min(filter.z, binValue);
				binValue -= offset;
				filter.zw -= offset.xx;
				binValue = min(filter.w, binValue);
				filter.w -= binValue;
				float luminance = GetLuminanceFromHistogramBin(float(i) / float(HISTOGRAM_BINS), _ScaleOffsetRes.xy);
				filter.xy += float2(luminance * binValue, binValue);
			}

			float GetAverageLuminance(float maxHistogramValue)
			{
				uint i;
				float totalSum = 0.0;
				[loop]
				for (i = 0; i < HISTOGRAM_BINS; i++) totalSum += GetBinValue(i, maxHistogramValue);
				float4 filter = float4(0.0, 0.0, totalSum * _Params.xy);
				[loop]
				for (i = 0; i < HISTOGRAM_BINS; i++) FilterLuminance(i, maxHistogramValue, filter);
				return clamp(filter.x / max(filter.y, 1.0e-4), _Params.z, _Params.w);
			}

			float GetExposureMultiplier(float avgLuminance)
			{
				avgLuminance = max(1.0e-4, avgLuminance);
				#if AUTO_KEY_VALUE
					half keyValue = 1.03 - (2.0 / (2.0 + log2(avgLuminance + 1.0)));
				#else
					half keyValue = _ExposureCompensation;
				#endif
				half exposure = keyValue / avgLuminance;
				return exposure;
			}

			float InterpolateExposure(float newExposure, float oldExposure)
			{
				float delta = newExposure - oldExposure;
				float speed = delta > 0.0 ? _Speed.x : _Speed.y;
				float exposure = oldExposure + delta * (1.0 - exp2(-unity_DeltaTime.x * speed));
				return exposure;
			}

			void SetVertexShader(inout float4 vertex : POSITION, inout float2 texcoord : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 SetPixelShader(float4 vertex : POSITION, float2 texcoord : TEXCOORD0) : SV_Target
			{
				float maxValue = 1.0 / FindMaxHistogramValue();
				float avgLuminance = GetAverageLuminance(maxValue);
				float exposure = GetExposureMultiplier(avgLuminance);
				float prevExposure = tex2D(_MainTex, (0.5).xx);
				exposure = InterpolateExposure(exposure, prevExposure);
				return exposure.xxxx;
			}
			
            ENDCG
        }

    }
}