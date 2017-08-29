//source: https://www.shadertoy.com/view/MdlXz8
Shader "Water Caustics"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
						
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float time = _Time.g*0.5+23.0;
				float2 uv = ps.uv.xy;
				float tau = 6.28318530718;
				float2 p = fmod(uv*tau, tau)-250.0;
				float2 i = float2(p);
				float c = 1.0;
				float inten = 0.005;
				for (int n = 0; n < 5; n++) 
				{
					float t = time * (1.0 - (3.5 / float(n+1)));
					i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
					c += 1.0/length(float2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
				}
				c /= float(5);
				c = 1.17-pow(c, 1.4);
				float t = pow(abs(c),8.0);
				float3 color = float3(t,t,t);
				color = clamp(color + float3(0.0, 0.35, 0.5), 0.0, 1.0);
				return float4(color, 1.0);
			}
			ENDCG
		}
	}
}