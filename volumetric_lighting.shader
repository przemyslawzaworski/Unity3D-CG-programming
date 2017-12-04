Shader "Volumetric Lighting"
{
	Properties
	{
		pattern ("Texture", 2D) = "white" {} 
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D pattern;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0; 
			};
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				float color = 0.0;
				for(int i=0;i<192;++i)
				{
					float2 p=(uv*asin(dot(uv,uv)*float(i)*0.01)/dot(uv,uv));
					p.x-=_Time.g*0.5;
					color+=tex2Dlod(pattern,float4(p*0.2,0.0,0.0)).r*0.01;
				}
				return float4(color,0.0,0.0,1.0);			
			}
			ENDCG
		}
	}
}