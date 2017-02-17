Shader "Transparency"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	Subshader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Pass
		{
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;

			struct custom_type
			{
				float4 clip_space_vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (float4 object_space_vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.clip_space_vertex = mul (UNITY_MATRIX_MVP,object_space_vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				return tex2D (_MainTex,ps.uv);
			}

			ENDCG
		}
	}
}