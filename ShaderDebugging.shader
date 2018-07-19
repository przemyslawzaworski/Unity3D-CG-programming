Shader "Shader Debugging"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.5
			
			RWStructuredBuffer<float4> buffer : register(u1);
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				float4 p = float4(sin(_Time.g)*0.5+0.5,0.2,0.321,0.789);   //set custom variable
				buffer[0] = p;   //write value to buffer
				return lerp(0..xxxx, float4(uv,0,1), step(uv.x,p.x));
			}
			ENDCG
		}
	}
}