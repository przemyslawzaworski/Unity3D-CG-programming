Shader "Fog"   //Exponential Squared Fog
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogColor ("Fog Color (RGB)", Color) = (0.5, 0.5, 0.5, 1.0)
		_FogDensity ("Fog Density", Float) = 0.005
	}
	SubShader
	{
		Fog { Mode off }
		Pass
		{
			CGPROGRAM
			#pragma vertex VS
			#pragma fragment PS
			
			sampler2D _MainTex;
			float4 _FogColor;
			float _FogDensity;
			
			void VS (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0,out float depth:TEXCOORD1)
			{
				vertex = UnityObjectToClipPos(vertex);
				depth = vertex.w;
			}
			
			float4 PS (float4 vertex:POSITION,float2 uv:TEXCOORD0,float depth:TEXCOORD1) : SV_TARGET
			{
				float FogFactor = (_FogDensity / sqrt(log(2.0))) * depth; 
				FogFactor = saturate(exp2(-FogFactor*FogFactor));	
				return lerp(_FogColor, tex2D(_MainTex,uv), FogFactor);
			}
			ENDCG
		}
	}
}