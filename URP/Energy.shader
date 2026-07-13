// Unlit + transparency + URP + VR support
Shader "Energy URP"
{
    Properties
    {
        [NoScaleOffset] _Hash("RGBA Noise Medium", 2D) = "black" {}	
        _MainColor("Color", Color) =  (0.5, 0.6, 0.5, 1.0)
        _Speed("Speed", Range(0.0,2.0)) = 0.5	
        _OpacityThreshold("Opacity Threshold", Range(0.0,1.0)) = 0.0
        _OpacityPower("Opacity Power", Range(0.0,5.0)) = 2.0
        _EnergyHeight("Height", Range(0.0,1.0)) = 0.5		
    }
	SubShader 
	{
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"Queue"="Transparent"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		CBUFFER_START(UnityPerMaterial)
		float4 _BaseMap_ST;
		float4 _BaseColor;
		float _Cutoff;
		float4 _Color;
		sampler2D _Hash;
		float4 _MainColor;
		float _Speed;
		float _OpacityThreshold, _OpacityPower;
		float _EnergyHeight;
		CBUFFER_END
		ENDHLSL

		Pass
		{
			Name "Unlit"
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma shader_feature _ALPHATEST_ON

			struct Attributes 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			float Hash(float2 p)
			{
				float3 p3  = frac(float3(p.xyx) * .1031);
				p3 += dot(p3, p3.yzx + 33.33);
				return frac((p3.x + p3.y) * p3.z);
			}
				
			float Noise(float2 uv)
			{
				float2 p = floor(uv);
				float2 f = frac(uv);
				f = f * f * (3.0 - 2.0 * f);
				//return tex2Dlod(_Hash,float4((p.xy + f.xy) / 256.0, 0.0, 0.0)).y;  
				float n = lerp(
					lerp(Hash(p),Hash(p+float2(1.0,0.0)),f.x),
					lerp(Hash(p+float2(0.0,1.0)),Hash(p+float2(1.0,1.0)),f.x),f.y);
				return n ;
			}

			float FractalBrownianMotion(float2 uv) 
			{
				float value = 0.0;
				float amplitude = 0.5;
				for (int i = 0; i < 5; i++) 
				{
					value += amplitude * Noise(uv);
					uv *= 2.0;
					amplitude *= 0.5;
				}
				return value;
			}

			float4 Energy(float2 uv)
			{
				uv.x *= 20.0;
				float layer1 = FractalBrownianMotion(float2(uv.x + _Time.g * _Speed, 0.0));
				layer1 = layer1 * pow(layer1 - uv.y + _EnergyHeight, 1.0);
				float layer2 = FractalBrownianMotion(float2(0.0, uv.x - _Time.g * _Speed));
				layer2 = layer2 * pow(layer2 - uv.y + _EnergyHeight, 1.0);
				float layer = layer1 + layer2;
				float alpha = layer * _OpacityPower;
				alpha = alpha < _OpacityThreshold ? 0.0 : alpha;
				return float4(_MainColor.rgb * layer, alpha);			
			}
	
			Varyings VSMain(Attributes IN) 
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				return OUT;
			}

			float4 PSMain(Varyings IN) : SV_Target
			{
				float2 uv = IN.uv.xy;
				return Energy(uv);
			}
			ENDHLSL
		}
	}
}