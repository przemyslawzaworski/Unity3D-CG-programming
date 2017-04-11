Shader "Brightness_Contrast_Saturation"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		brightness ("Brightness",Float) = 0.0
		contrast ("Contrast",Float) = 1.0
		saturation ("Saturation",Float) = 1.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			float brightness;
			float contrast; 
			float saturation;

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float4x4 brightnessMatrix (float brightness)
			{
			    return float4x4( 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, brightness, brightness, brightness, 1 );
			}

			float4x4 contrastMatrix (float contrast)
			{
				float t = (1.0-contrast)*0.5;
			    return float4x4 (contrast, 0, 0, 0, 0, contrast, 0, 0, 0, 0, contrast, 0, t, t, t, 1);
			}

			float4x4 saturationMatrix (float saturation)
			{
			    float3 luminance = float3(0.3086, 0.6094, 0.0820);
			    float oneMinusSat = 1.0 - saturation;
			    float3 red = float3 (luminance.x * oneMinusSat,luminance.x * oneMinusSat,luminance.x * oneMinusSat);
			    red+=float3 (saturation, 0, 0);
			    float3 green = float3 (luminance.y * oneMinusSat,luminance.y * oneMinusSat,luminance.y * oneMinusSat);
			    green+=float3 (0, saturation, 0);
			    float3 blue = float3 (luminance.z * oneMinusSat,luminance.z * oneMinusSat,luminance.z * oneMinusSat);
			    blue+=float3 (0, 0, saturation);
			    return float4x4 (red, 0, green, 0, blue, 0, 0, 0, 0, 1);
			}

			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float4 color = tex2D (_MainTex,ps.uv.xy);
				color = mul (color,saturationMatrix(saturation));
				color = mul (color,contrastMatrix(contrast));
				color = mul (color,brightnessMatrix(brightness));
				return color;
			}

			ENDCG
		}
	}
}
