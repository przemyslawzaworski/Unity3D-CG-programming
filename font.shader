//source:https://www.shadertoy.com/view/4sBfRd
Shader "Font"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {} //assign font.png (texture source: www.shadertoy.com)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			sampler2D _MainTex;
						
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				uint t[12] = {72,69,76,76,79,32,87,79,82,76,68,33}; //every number is another char
				float2 position = float2(0.5,1.0); //xy coordinates (x: 0.0->1.0 y: 0.0->2.0 )
				float2 U = ps.uv.xy*2.0-position; 
				float c = 0.0;
				float3 d = float3(1.0,1.0,1.0); //RGB font color
				for (int i=0; i<12;i++,U.x-=.1)
				{
					 c +=(length(U-.06)<.06)?tex2D(_MainTex,U*.5+frac(float2(t[i],15-t[i]/16)/16.)).x:0.0;
				}
				return float4(c*d.x,c*d.y,c*d.z,1.0);
			}
			ENDCG
		}
	}
}