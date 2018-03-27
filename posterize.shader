Shader "Posterize"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_steps ("Steps",Float) = 5.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			sampler2D _MainTex;
			float _steps;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float3 posterize (float3 c, float s)
			{
				return floor(c*s)/(s-1);
			}
			
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float3 input = tex2D(_MainTex,ps.uv);
				float3 color = posterize(input,_steps);
				return float4(color,1.0);
			}

			ENDCG

		}
	}
}