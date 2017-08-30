Shader "Vignette Filter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_intensity ("Intensity",Float) = 15.0
		_range ("Range",Float) = 0.25
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
			float _intensity;
			float _range;
			
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
				float2 u = ps.uv.xy;
				float2 t = u*(1.0-u);
				float v = pow(t.x*t.y*_intensity,_range);
				return tex2D(_MainTex,u)*float4(v,v,v,1);		
			}
			ENDCG
		}
	}
}