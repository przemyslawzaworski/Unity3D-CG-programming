Shader "Face"
{
	SubShader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0, bool IsFacing:SV_IsFrontFace) : SV_TARGET
			{
				return IsFacing ? float4(1,0,0,1) : float4(0,0,1,1);
			}
			ENDCG
		}
	}
}