Shader "Waveform"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0
			
			float SoundBuffer[512];
			
			void VSMain (inout float4 Vertex:POSITION, inout float2 uv:TEXCOORD0)
			{
				Vertex = UnityObjectToClipPos (Vertex);
			}
		
			void PSMain (float4 Vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 iResolution = float2(512., 512.);
				float2 fragCoord = uv * iResolution;
				float x = (fragCoord.x / iResolution.x) * 2.0 - 1.0;
				float y = SoundBuffer[fragCoord.x] * iResolution.y; 
				float c = 1.0 - smoothstep(0.0, 5.0, abs(fragCoord.y - y)); 
				fragColor = float4(c.xxx, 1.0);
			}
			ENDCG
		}
	}
}