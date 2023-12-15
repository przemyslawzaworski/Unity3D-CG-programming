Shader "RenderToTextureURP"
{
	SubShader
	{
		Pass
		{
			ZTest Off
			ZWrite Off
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			Texture2D _Texture;
			SamplerState sampler_linear_repeat;
			float _BokehRadius, _BokehContrast;
			int _BokehRenderMode;

			// Bokeh Disc effect by Dave Hoskins
			float3 Bokeh(Texture2D surface, SamplerState state, float2 uv, float radius, float contrast)
			{
				float3 accumulation = float3(0.0, 0.0, 0.0);
				float3 divider = accumulation;
				float spread = 1.0;
				int samples = 128;
				float2 angle = float2(0.0, radius * 0.01 / sqrt(float(samples)));
				float2x2 rotation = float2x2(cos(2.3999632), sin(2.3999632), -sin(2.3999632), cos(2.3999632));
				for (int j = 0; j < samples; j++)
				{
					spread += 1.0 / spread;
					angle = mul(angle, rotation);
					float3 color = surface.Sample(state, uv + (spread - 1.0) * angle).xyz;
					color = (contrast > 1.0) ? color * color * contrast : color;
					float3 bokeh = pow(color, float3(4.0, 4.0, 4.0));
					accumulation += color * bokeh;
					divider += bokeh;
				}
				return accumulation / divider;
			}
	
			float4 VSMain (float4 vertex : POSITION, inout float2 uv : TEXCOORD0) : SV_POSITION
			{
				uv.y = (_BokehRenderMode == 0) ? 1.0 - uv.y : uv.y;
				return vertex;
			}

			float4 PSMain (float4 vertex : SV_POSITION, float2 uv : TEXCOORD0) : SV_Target
			{
				float3 color = Bokeh(_Texture, sampler_linear_repeat, uv, _BokehRadius, _BokehContrast);
				return float4(color, 1.0);
			}
			ENDHLSL
		}
	}
}
