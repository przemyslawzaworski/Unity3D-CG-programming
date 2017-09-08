//source: https://www.shadertoy.com/view/XlXcW4
Shader "Integer Hash"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			static const uint k = 1103515245U;
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float3 hash( uint3 x )
			{
				x = ((x>>8U)^x.yzx)*k;
				x = ((x>>8U)^x.yzx)*k;
				x = ((x>>8U)^x.yzx)*k;				
				return float3(x)*(1.0/float(0xffffffffU));
			}
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				uint2 resolution = uint2 (1024,1024);
				uint3 p = uint3(ps.uv.xy*resolution,_Time.g*60);
				return float4(hash(p),1.0);	
			}
			ENDCG
		}
	}
}