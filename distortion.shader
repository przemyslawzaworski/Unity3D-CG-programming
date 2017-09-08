Shader "Distortion"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		A("A",Range(1.0,20.0)) = 5.0	
		B("B",Range(1.0,20.0)) = 5.0			
	}
	Subshader
	{
		Pass
		{
			Cull off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			sampler2D _MainTex;
			float A,B;
			
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

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				uv.y+=cos(uv.x*A+_Time.g)/B;
				return tex2D(_MainTex,uv);	
			}
			ENDCG
		}
	}
}