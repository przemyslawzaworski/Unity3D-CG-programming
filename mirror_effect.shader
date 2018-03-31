Shader "Mirror Effect" 
{
	Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
		[KeywordEnum(Vertical,Horizontal)] _mode("Mode", Float) = 0
	}
	SubShader 
	{
		Cull Off
		Tags {"RenderType"="Opaque"}
		Pass 
		{                     
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			sampler2D _MainTex;
			float _mode;
			
			struct structure 
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos( vertex );			
				vs.uv = uv;
				return vs;
			}
			
			float4 pixel_shader(structure ps) : COLOR 
			{
				float2 uv = ps.uv.xy;
				if (_mode==0.0)
				{
					if (uv.x>0.5) 
						return tex2D(_MainTex,float2(0.5-(uv.x-0.5),uv.y));
					else
						return tex2D(_MainTex,uv);
				}
				else
				{
					if (uv.y>0.5) 
						return tex2D(_MainTex,float2(uv.x,0.5-(uv.y-0.5)));
					else
						return tex2D(_MainTex,uv);
				}				
			}
			ENDCG
		}
	}
}