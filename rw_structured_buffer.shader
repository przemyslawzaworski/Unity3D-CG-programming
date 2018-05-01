//https://github.com/przemyslawzaworski
//Assign displacement map (R) to properties.

Shader "RW Structured Buffer"
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
			#pragma target 5.0

			sampler2D _MainTex;
			uniform RWStructuredBuffer<float3> data : register(u1);

			struct APPDATA
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				uint id : SV_VertexID;		
			};

			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			SHADERDATA vertex_shader (APPDATA IN)
			{
				SHADERDATA vs;
				IN.vertex.y = 0.0-tex2Dlod(_MainTex,float4(IN.uv,0,0)).r*(sin(_Time.g)*0.5+0.5);
				data[IN.id] = IN.vertex.xyz;
				vs.vertex = UnityObjectToClipPos(IN.vertex);
				vs.uv = IN.uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{
				return tex2D(_MainTex,ps.uv); 
			}

			ENDCG
		}
	}
}