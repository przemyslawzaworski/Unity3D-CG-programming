Shader "Texture Array"
{
	Properties
	{
		_TextureArray ("Texture Array", 2DArray) = "" {}
		_Index ("Slices", Range(0,1)) = 1
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			
			Texture2DArray _TextureArray : register(t0);
			float _Index;
			SamplerState sampler_linear_repeat;
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				return _TextureArray.Sample( sampler_linear_repeat, float3( uv, _Index ) );
			}
			ENDCG
		}
	}
}