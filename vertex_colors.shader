Shader "Vertex Colors"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color :COLOR;
			};
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0, float4 color:COLOR)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				vs.color = color;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				return ps.color;
			}

			ENDCG

		}
	}
}