Shader "Paint 3D"
{
	Properties
	{
		[HideInInspector]
		_vector ("Vector", Vector) = (-10,-10,0,0)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float4 _vector;

			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float t = length(ps.uv-_vector.xy)*3.0;
				return float4(t,t,0.0,1.0); 
			}

			ENDCG
		}
	}
}