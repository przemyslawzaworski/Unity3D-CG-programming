Shader "Hidden/CAS"
{
	Subshader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			Texture2D _MainTex;
			float _Amount, _Radius, _InvertY;

			// Contrast Adaptive Sharpening (CAS)
			// Reference: Lou Kramer, FidelityFX CAS, AMD Developer Day 2019,
			// https://gpuopen.com/wp-content/uploads/2019/07/FidelityFX-CAS.pptx
			float3 ContrastAdaptiveSharpening (Texture2D tex, int2 texcoord, float knob, float radius)
			{
				float3 a = tex.Load(int3(texcoord + int2( 0.0, -1.0) * radius, 0)).rgb;
				float3 b = tex.Load(int3(texcoord + int2(-1.0,  0.0) * radius, 0)).rgb;
				float3 c = tex.Load(int3(texcoord + int2( 0.0,  0.0) * radius, 0)).rgb;
				float3 d = tex.Load(int3(texcoord + int2( 1.0,  0.0) * radius, 0)).rgb;
				float3 e = tex.Load(int3(texcoord + int2( 0.0,  1.0) * radius, 0)).rgb;
				float m = min(a.g, min(b.g, min(c.g, min(d.g, e.g))));
				float n = max(a.g, max(b.g, max(c.g, max(d.g, e.g))));
				float w = sqrt(min(1.0 - n, m) / n) * lerp(-0.125, -0.2, knob);
				return (w * (a + b + d + e) + c) / (4.0 * w + 1.0);
			}

			float4 VSMain (float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex : SV_POSITION) : SV_Target
			{
				int2 uv = int2(vertex.xy);
				if (_InvertY > 0.5) uv.y = _ScreenParams.y - uv.y - 1;
				return float4(ContrastAdaptiveSharpening(_MainTex, uv, _Amount, _Radius), 1.0);
			}
			ENDCG
		}
	}
}