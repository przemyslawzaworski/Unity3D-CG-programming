Shader "ProgressiveRendering"
{
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler2D _MainImage;
			sampler2D _Accumulation;
			int _Frame;

			void VSMain (inout float4 vertex : POSITION, inout float2 uv : TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			void PSMain (float4 vertex : POSITION, float2 uv : TEXCOORD0, out float4 fragColor : SV_Target) 
			{
				float4 currentFrame = tex2D(_MainImage, uv);
				float4 accumulation = tex2D(_Accumulation, uv);
				fragColor = (accumulation * _Frame + currentFrame) / (_Frame + 1);
			}
			ENDCG
		}
	}
}