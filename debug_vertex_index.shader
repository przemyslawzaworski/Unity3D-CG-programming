Shader "Debug Vertex Index"
{
	Properties
	{
		[HideInInspector]
		amount ("amount", Int) = 0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			int amount;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				uint id : TEXCOORD1;
			};

			structure vertex_shader (uint id:SV_VertexID,float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.id = id;
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : SV_TARGET
			{
				float t = float(ps.id)/float(amount);
				return float4(t,t,t,1.0);
			}

			ENDCG
		}
	}
}