// Original source: https://github.com/crosire/reshade-shaders/blob/master/Shaders/DepthHaze.fx
Shader "Reshade/DepthHaze"
{
	Subshader
	{	
		CGINCLUDE
		#pragma vertex PostProcessVS
		#pragma target 5.0

		sampler2D Otis_SamplerFragmentBuffer1;
		sampler2D Otis_SamplerFragmentBuffer2;
		sampler2D BackBuffer;
		sampler2D _CameraDepthTexture;

		static const float2 ASPECT_RATIO = float2(1.0, _ScreenParams.x / _ScreenParams.y);
		static const float2 BUFFER_PIXEL_SIZE = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
		static const float2 SCREEN_SIZE = float2(_ScreenParams.x, _ScreenParams.y);

		float EffectStrength, FogStart, FogFactor;
		float4 FogColor;

		#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
		#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
		#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0

		class ReShade
		{
			static float GetLinearizedDepth(float2 uv)
			{
				#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
					uv.y = 1.0 - uv.y;
				#endif
				float depth = tex2Dlod(_CameraDepthTexture, float4(uv, 0, 0)).x;
				#if RESHADE_DEPTH_INPUT_IS_REVERSED
					depth = 1.0 - depth;
				#endif
				const float N = 1.0;
				depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
				return saturate(depth);
			}
		};

		float CalculateWeight(float distanceFromSource, float sourceDepth, float neighborDepth)
		{
			return (1.0 - abs(sourceDepth - neighborDepth)) * (1/distanceFromSource) * neighborDepth;
		}

		void PostProcessVS (inout float4 vertex:POSITION, inout float2 texcoord:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}		
				
		ENDCG
		
		Pass
		{
			CGPROGRAM
			#pragma fragment PS_Otis_DEH_BlockBlurHorizontal
			
			void PS_Otis_DEH_BlockBlurHorizontal (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0, out float4 outFragment : SV_Target0)
			{
				float4 color = tex2D(BackBuffer, texcoord);
				float colorDepth = ReShade::GetLinearizedDepth(texcoord).r;
				float n = 1.0;
				
				[loop]
				for(float i = 1; i < 5; ++i) 
				{
					float2 sourceCoords = texcoord + float2(i * BUFFER_PIXEL_SIZE.x, 0.0);
					float weight = CalculateWeight(i, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
					color += (tex2D(BackBuffer, sourceCoords) * weight);
					n+=weight;

					sourceCoords = texcoord - float2(i * BUFFER_PIXEL_SIZE.x, 0.0);
					weight = CalculateWeight(i, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
					color += (tex2D(BackBuffer, sourceCoords) * weight);
					n+=weight;
				}
				outFragment = color/n;
			}
			ENDCG
		}
		
		Pass
		{
			CGPROGRAM
			#pragma fragment PS_Otis_DEH_BlockBlurVertical
			
			void PS_Otis_DEH_BlockBlurVertical (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0, out float4 outFragment : SV_Target0)
			{
				float4 color = tex2D(Otis_SamplerFragmentBuffer1, texcoord);
				float colorDepth = ReShade::GetLinearizedDepth(texcoord).r;
				float n=1.0;
				
				[loop]
				for(float j = 1; j < 5; ++j) 
				{
					float2 sourceCoords = texcoord + float2(0.0, j * BUFFER_PIXEL_SIZE.y);
					float weight = CalculateWeight(j, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
					color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
					n+=weight;

					sourceCoords = texcoord - float2(0.0, j * BUFFER_PIXEL_SIZE.y);
					weight = CalculateWeight(j, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
					color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
					n+=weight;
				}
				outFragment = color/n;
				
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_Otis_DEH_BlendBlurWithDepthBuffer

			void PS_Otis_DEH_BlendBlurWithDepthBuffer (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0, out float4 fragment: SV_Target0)
			{
				float depth = ReShade::GetLinearizedDepth(texcoord).r;
				float4 blendedFragment = lerp(tex2D(BackBuffer, texcoord), tex2D(Otis_SamplerFragmentBuffer2, texcoord), clamp(depth  * EffectStrength, 0.0, 1.0)); 
				float yFactor = clamp(texcoord.y > 0.5 ? 1-((texcoord.y-0.5)*2.0) : texcoord.y * 2.0, 0, 1);
				fragment = lerp(blendedFragment, float4(FogColor.rgb, blendedFragment.r), clamp((depth-FogStart) * yFactor * FogFactor, 0.0, 1.0));				
			}
			ENDCG
		}
	}
}