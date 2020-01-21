// Original source: https://github.com/crosire/reshade-shaders/blob/master/Shaders/Cartoon.fx
Shader "Reshade/Cartoon"
{
	Subshader
	{	
		CGINCLUDE
		#pragma vertex PostProcessVS
		#pragma target 5.0

		sampler2D BackBuffer;

		static const float2 ASPECT_RATIO = float2(1.0, _ScreenParams.x / _ScreenParams.y);
		static const float2 BUFFER_PIXEL_SIZE = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
		static const float2 SCREEN_SIZE = float2(_ScreenParams.x, _ScreenParams.y);

		float Power, EdgeSlope;

		void PostProcessVS (inout float4 vertex:POSITION, inout float2 texcoord:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}		
				
		ENDCG
		
		Pass
		{
			CGPROGRAM
			#pragma fragment CartoonPass
			
			float4 CartoonPass (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0) : SV_Target0
			{
				float3 color = tex2D(BackBuffer, texcoord).rgb;
				const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
				float diff1 = dot(coefLuma, tex2D(BackBuffer, texcoord + BUFFER_PIXEL_SIZE).rgb);
				diff1 = dot(float4(coefLuma, -1.0), float4(tex2D(BackBuffer, texcoord - BUFFER_PIXEL_SIZE).rgb , diff1));
				float diff2 = dot(coefLuma, tex2D(BackBuffer, texcoord + BUFFER_PIXEL_SIZE * float2(1, -1)).rgb);
				diff2 = dot(float4(coefLuma, -1.0), float4(tex2D(BackBuffer, texcoord + BUFFER_PIXEL_SIZE * float2(-1, 1)).rgb , diff2));
				float edge = dot(float2(diff1, diff2), float2(diff1, diff2));
				return float4(saturate(pow(abs(edge), EdgeSlope) * -Power + color), 1.0);
			}
			ENDCG
		}
		
	}
}