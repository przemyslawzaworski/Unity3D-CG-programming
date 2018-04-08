Shader "Billboard"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		[Toggle] _flip("Flip UV", Float) = 0
	}
	Subshader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#define UNITY_SHADER_NO_UPGRADE 1

			sampler2D _MainTex;
			float _flip;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				float4x4 m = UNITY_MATRIX_MV;
				m._m00 = -1.0/length(unity_WorldToObject[0].xyz);
				m._m10 = 0.0f;
				m._m20 = 0.0f;
				m._m01 = 0.0f;
				m._m11 = -1.0/length(unity_WorldToObject[1].xyz);
				m._m21 = 0.0f;
				m._m02 = 0.0f;
				m._m12 = 0.0f;
				m._m22 = -1.0/length(unity_WorldToObject[2].xyz);
				vs.vertex = mul(UNITY_MATRIX_P, mul(m,vertex));
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{	
				if (_flip==1.0)
					return tex2D(_MainTex,ps.uv); 
				else 
					return tex2D(_MainTex,float2(1.0-ps.uv.x,1.0-ps.uv.y)); 				
			}

			ENDCG
		}
	}
}