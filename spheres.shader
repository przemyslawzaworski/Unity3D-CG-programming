Shader "Spheres"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			
			float2 hash( float2 p )
			{
				float2 q = float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
				return frac(sin(q)*43758.5453);
			}
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				uv = float2(2.0*uv-1.0);
				float2 k = float2(0.0,0.0); 
				for (float i=0.0;i<100.0;i++)
				{
					float2 h = hash(float2(i,i));
					float2 p = cos(h*_Time.g);
					float d = length(uv-p);
					k+=smoothstep(0.04,0.03,d);
				}
				return float4(k,0.0,1.0);
			}
			ENDCG
		}
	}
}