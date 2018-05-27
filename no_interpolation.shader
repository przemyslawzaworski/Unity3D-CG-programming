Shader "No interpolation"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
							
			struct SHADERDATA
			{
				linear float4 Vertex : SV_POSITION;
				nointerpolation float4 Point : TEXCOORD0;
			};
		
			SHADERDATA vertex_shader (float4 vertex:POSITION)
			{
				SHADERDATA vs;
				vs.Vertex = UnityObjectToClipPos (vertex);
				vs.Point = vertex;
				return vs;
			}

			void pixel_shader (in SHADERDATA ps, out float4 result : SV_Target0 ) 
			{
				 result = ps.Point;
			}

			ENDCG
		}
	}
}