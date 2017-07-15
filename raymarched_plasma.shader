// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// source: https://www.shadertoy.com/view/ldSfzm
Shader "Raymarched plasma"
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
			
			float m(float3 p) 
			{ 
				p.z+=5.*_Time.g; 
				return length(.2*sin(p.x-p.y)+cos(p/3.)-.1*sin(1.5*p.x))-.8;
			}

			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 u = ps.uv.xy;
				float3 d=.5-float3(u,0),o=d;
				for(int i=0;i<64;i++) o+=m(o)*d;
				return  float4(abs(m(o+d)*float3(.3,.15,.1)+m(o*.5)*float3(.1,.05,0))*(8.-o.x/2.),1.0);
			}
			ENDCG
		}
	}
}