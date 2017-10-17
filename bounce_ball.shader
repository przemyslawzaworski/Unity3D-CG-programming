Shader "Bounce Ball"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				float g = 1.0;
				float h = 1.8;
				float v,d ; 
				if (_Time.g<0.94) 
				{
					v=sqrt(2.0*g*h);
					d=length(uv+float2(0,-0.8+v*_Time.g));
				}
				else 
				if (_Time.g>=0.94 && _Time.g<1.61)
				{
					v=sqrt(2.0*g*0.5*h);
					d=length(uv+float2(0,1.0-v*(_Time.g-0.94)));
				}
				else 
				if (_Time.g>=1.61 && _Time.g<2.5)
				{
					v=sqrt(2.0*g*0.25*h);
					d=length(uv+float2(0,0.1+v*(_Time.g-1.61)));
				}
				else d=length(uv+float2(0,0.9));
				float4 s = lerp(float4(1,0,0,1),float4(0,0,0,1),step(0.1,d));
				return max(s,float4(0,0,0,1));	
			}			
			ENDCG
		}
	}
}