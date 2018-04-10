//  https://github.com/przemyslawzaworski

Shader "Scale"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float4 vertex_shader (float4 vertex:POSITION) : SV_POSITION
			{
				float4 w = mul(unity_ObjectToWorld, vertex);   //transform local vertex to world space
				w.y=w.y*3.0;   //scale vertex in world coordinates
				return mul(UNITY_MATRIX_VP,w);   //matrix multiplication (current view-projection matrix and world space vertex)
			}

			float4 pixel_shader (void) : SV_TARGET
			{
				return 0;
			}

			ENDCG
		}
	}
}
