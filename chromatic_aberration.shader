Shader "Chromatic Aberration"
{
	Properties
	{
		[HideInInspector]
		_MainTex ("Texture", 2D) = "white" {}
		_amount ("Amount",Range(0.0,0.01)) = 0.005
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
			float _amount;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float3 color;
				color.r = tex2D( _MainTex, float2(uv.x+_amount,uv.y) ).r;
				color.g = tex2D( _MainTex, uv ).g;
				color.b = tex2D( _MainTex, float2(uv.x-_amount,uv.y) ).b;
				color *= (1.0 - _amount* 0.5);			
				return float4(color,1.0);		
			}
			ENDCG
		}
	}
}