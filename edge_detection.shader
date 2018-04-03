//reference: http://blog.ruofeidu.com/simplest-fatest-glsl-edge-detection-using-fwidth/

Shader "Edge detection"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
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
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float sigmoid(float a, float f)
			{
				return 1.0/(1.0+exp(-f*a));
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
				float2 uv = ps.uv.xy;			
				float e = length(fwidth(tex2D(_MainTex, uv)));
				e = sigmoid(e - 0.2, 32.0); 
				return float4(float3(e,e,e), 1.0); 
			}

			ENDCG
		}
	}
}