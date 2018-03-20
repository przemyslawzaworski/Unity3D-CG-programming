Shader "Matrix example"
{
	Subshader
	{
		Pass
		{
			Cull Off
			HLSLPROGRAM
			#pragma vertex v
			#pragma fragment p

			void v (uint i: SV_VertexID, out float4 t: position)
			{
				t = float4(float2((i<< 1) & 2, i & 2) * float2(2, -2) - float2(1, -1), 0, 1);
			}
 
			void p (out float4 c:COLOR)
			{
				matrix <float, 2, 2> a = { 1.0, 2.0, 0.0, 1.0 };
				matrix <float, 2, 1> b = { 1.0, 0.0};
				c = float4(mul(a,b),0,1);  //red fullscreen quad
			}
 
			ENDHLSL
		}
	}
}