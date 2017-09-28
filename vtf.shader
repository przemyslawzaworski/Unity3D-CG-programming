//http://www.nvidia.com/object/using_vertex_textures.html 
Shader "Vertex Texture Fetch"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_displacement("Displacement",Range(0.0,8.0)) = 3.0
	}
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
			
			sampler2D _MainTex;
			float _displacement;
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				float4 heightmap = tex2Dlod (_MainTex,float4(uv.xy,0,0));
				vs.vertex.y += heightmap.r * _displacement;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				return tex2D(_MainTex,ps.uv);
			}
			ENDCG
		}
	}
}