Shader "Mesh unwrapping"
{
	Properties
	{ 
		_MainTex ("Texture", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Texture2D _MainTex;
			SamplerState sampler_MainTex; 
			float4 _MainTex_ST;
		
			void vertex_shader(in float4 vertex:POSITION,in float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = float4(uv.x,1.0-uv.y, 0.01, vertex.w);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = ps.uv.xy;
				fragColor =_MainTex.Sample(sampler_MainTex, ps.uv);
			}
			
			ENDCG
		}
	}
}