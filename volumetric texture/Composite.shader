Shader "Hidden/Ray Marching/Composite" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "" {}
		_BlendTex ("Blend (RGB)", 2D) = "" {}	
	}
	Subshader 
	{
		Pass 
		{
			ZTest Always Cull Off ZWrite Off	

			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
		
			struct custom_type 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
		
			sampler2D _MainTex;
			sampler2D _BlendTex;
						
			custom_type vertex_shader(float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos(vertex);				
				vs.uv=uv;		
				return vs;
			}
			
			float4 pixel_shader(custom_type ps) : COLOR 
			{		
				float4 src = tex2D(_MainTex, ps.uv);
				float4 dst = tex2D(_BlendTex, ps.uv);
				return lerp(src,dst,dst.a);
			}

			ENDCG
		
		}
	}
}


