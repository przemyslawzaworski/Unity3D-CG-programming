// Original source: https://github.com/crosire/reshade-shaders/blob/master/Shaders/PPFX_SSDO.fx
// For best results, enable Linear Color Space in Player Settings
Shader "Reshade/PPFX-SSDO"
{
	Subshader
	{	
		CGINCLUDE
		#pragma vertex PostProcessVS
		#pragma target 5.0

		sampler2D SamplerColorLOD, SamplerViewSpace, SamplerSSDOA, SamplerSSDOB, SamplerSSDOC;
		sampler2D BackBuffer;
		sampler2D _CameraDepthTexture;

		static const float2 BUFFER_ASPECT_RATIO = float2(1.0, _ScreenParams.x / _ScreenParams.y);
		static const float2 BUFFER_PIXEL_SIZE = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
		static const float2 BUFFER_SCREEN_SIZE = float2(_ScreenParams.x, _ScreenParams.y);

		float pSSDOIntensity, pSSDOAmount, pSSDOBounceMultiplier, pSSDOBounceSaturation, pSSDOSampleRange; 
		int pSSDOSampleAmount, pSSDOSourceLOD, pSSDOBounceLOD, pSSDODebugMode;
		float pSSDOFilterRadius, pSSDOAngleThreshold, pSSDOFadeStart, pSSDOFadeEnd;			

		#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
		#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
		#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
		
		#define	pSSDOLOD					1.0
		#define	pSSDOFilterScale			1.0		
		static const float2 pxSize = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
		static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);
		#define ZNEAR 0.1
		#define ZFAR 30.0
		#define NOISE_SCREENSCALE float2((_ScreenParams.x*pSSDOLOD)/4.0,(_ScreenParams.y*pSSDOLOD)/4.0)			

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

		float linearDepth(float2 txCoords)
		{
			return ReShade::GetLinearizedDepth(txCoords);
		}

		float4 viewSpace(float2 txCoords)
		{
			float2 offsetS = float2(0.0,1.0)*pxSize;
			float2 offsetE = float2(1.0,0.0)*pxSize;
			float depth = linearDepth(txCoords);
			float depthS = linearDepth(txCoords+offsetS);
			float depthE = linearDepth(txCoords+offsetE);			
			float3 vsNormal = cross(float3((-offsetS)*depth,depth-depthS),float3(offsetE*depth,depth-depthE));
			return float4(normalize(vsNormal),depth);
		}

		#define SSDO_CONTRIB_RANGE (pSSDOSampleRange*(pxSize.y/pSSDOLOD))
		#define SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER 0.1

		float4 FX_SSDOScatter( float2 txCoords )
		{
			float sourceAxisDiv = pow(2.0,pSSDOSourceLOD);
			float2 texelSize = pxSize.xy*pow(2.0,pSSDOSourceLOD).xx;
			float4 vsOrig = tex2D(SamplerViewSpace,txCoords);
			float3 ssdo = 0.0;
			float randomDir = frac((dot(txCoords, float2(12.9898, 4.1414))) * 43758.5453);
			const float2 stepSize = (pSSDOSampleRange/(pSSDOSampleAmount*sourceAxisDiv))*texelSize;
			for (float offs=1.0;offs<=(float)pSSDOSampleAmount;offs++)
			{
				float2 fetchDir = normalize(frac(float2(randomDir*811.139795*offs,randomDir*297.719157*offs))*2.0-1.0);
				fetchDir *= sign(dot(normalize(float3(fetchDir.x,-fetchDir.y,1.0)),vsOrig.xyz)); // flip directions
				float2 fetchCoords = txCoords+fetchDir*stepSize*offs*max(0.75,offs/pSSDOSampleAmount);
				float4 vsFetch = tex2Dlod(SamplerViewSpace,float4(fetchCoords,0,pSSDOSourceLOD));				
				float3 albedoFetch = tex2Dlod(SamplerColorLOD,float4(fetchCoords,0,pSSDOBounceLOD)).xyz;
				albedoFetch = pow(albedoFetch,pSSDOBounceSaturation);
				albedoFetch = normalize(albedoFetch);
				albedoFetch *= pSSDOBounceMultiplier;
				albedoFetch = 1.0-albedoFetch;
				float3 dirVec = float3(fetchCoords.x-txCoords.x,txCoords.y-fetchCoords.y,vsOrig.w-vsFetch.w);
				dirVec.xy *= vsOrig.w;
				float3 dirVecN = normalize(dirVec);
				float visibility = step(pSSDOAngleThreshold,dot(dirVecN,vsOrig.xyz)); 
				visibility *= sign(max(0.0,abs(length(vsOrig.xyz-vsFetch.xyz))-0.01));
				float distFade = max(0.0,SSDO_CONTRIB_RANGE-length(dirVec))/SSDO_CONTRIB_RANGE;
				ssdo += albedoFetch * visibility * distFade * distFade * pSSDOAmount;
			}
			ssdo /= pSSDOSampleAmount;		
			return float4(saturate(1.0-ssdo*smoothstep(pSSDOFadeEnd,pSSDOFadeStart,vsOrig.w)),vsOrig.w);
		}
		
		float4 FX_BlurBilatH( float2 txCoords, float radius )
		{
			float	texelSize = pxSize.x/pSSDOFilterScale;
			float4	pxInput = tex2D(SamplerSSDOB,txCoords);
			pxInput.xyz *= 0.5;
			float	sampleSum = 0.5;
			
			[loop]
			for (float hOffs=1.5; hOffs<radius; hOffs+=2.0)
			{
				float weight = 1.0;
				float2 fetchCoords = txCoords;
				fetchCoords.x += texelSize * hOffs;
				float4 fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
				float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
				pxInput.xyz+=fetch.xyz * contribFact;
				sampleSum += contribFact;
				fetchCoords = txCoords;
				fetchCoords.x -= texelSize * hOffs;
				fetch = tex2Dlod(SamplerSSDOB, float4(fetchCoords, 0.0, 0.0));
				contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
				pxInput.xyz+=fetch.xyz * contribFact;
				sampleSum += contribFact;
			}
			pxInput.xyz /= sampleSum;
			
			return pxInput;
		}

		float3 FX_BlurBilatV( float2 txCoords, float radius )
		{
			float	texelSize = pxSize.y/pSSDOFilterScale;
			float4	pxInput = tex2D(SamplerSSDOC,txCoords);
			pxInput.xyz *= 0.5;
			float	sampleSum = 0.5;
			
			[loop]
			for (float vOffs=1.5; vOffs<radius; vOffs+=2.0)
			{
				float weight = 1.0;
				float2 fetchCoords = txCoords;
				fetchCoords.y += texelSize * vOffs;
				float4 fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
				float contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
				pxInput.xyz+=fetch.xyz * contribFact;
				sampleSum += contribFact;
				fetchCoords = txCoords;
				fetchCoords.y -= texelSize * vOffs;
				fetch = tex2Dlod(SamplerSSDOC, float4(fetchCoords, 0.0, 0.0));
				contribFact = max(0.0,sign(SSDO_CONTRIB_RANGE*SSDO_BLUR_DEPTH_DISCONTINUITY_THRESH_MULTIPLIER-abs(pxInput.w-fetch.w))) * weight;
				pxInput.xyz+=fetch.xyz * contribFact;
				sampleSum += contribFact;
			}
			pxInput /= sampleSum;
			
			return pxInput.xyz;
		}		
	
		void PostProcessVS (inout float4 vertex:POSITION, inout float2 texcoord:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}		
				
		ENDCG
		
		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SetOriginal

			float4 PS_SetOriginal(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return tex2D(BackBuffer, txcoord.xy);
			}
			
			ENDCG
		}
		
		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOViewSpace
			
			float4 PS_SSDOViewSpace(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return viewSpace(txcoord.xy);
			}			

			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOScatter

			float4 PS_SSDOScatter(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return FX_SSDOScatter(txcoord.xy);
			}			
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOBlurScale

			float4 PS_SSDOBlurScale(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return tex2D(SamplerSSDOA, txcoord.xy);
			}	
			
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOBlurH

			float4 PS_SSDOBlurH(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return FX_BlurBilatH(txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale);
			}
			
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOBlurV

			float4 PS_SSDOBlurV(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				return float4(FX_BlurBilatV(txcoord.xy,pSSDOFilterRadius/pSSDOFilterScale).xyz,1.0);
			}			
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma fragment PS_SSDOMix
			
			float4 PS_SSDOMix(float4 vertex:SV_POSITION, float2 txcoord:TEXCOORD0) : COLOR
			{
				float3 ssdo = pow(tex2D(SamplerSSDOB, txcoord.xy).xyz,pSSDOIntensity.xxx);
				if (pSSDODebugMode == 1)
					return float4(pow(ssdo,2.2),1.0);
				else if (pSSDODebugMode == 2)
					return float4(pow(tex2D(SamplerSSDOA, txcoord.xy).xyz,2.2),1.0);
				else
					return float4(ssdo * tex2D(SamplerColorLOD, txcoord.xy).xyz,1.0);
			}
			ENDCG
		}
	}
}