Shader "Distance"
{
	Properties
	{
		_range ("Maximum distance",Float) = 10
		_color ("Color", Color) = (1.0,1.0,1.0,1.0)		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
						
			struct structure
			{
				float4 vertex : SV_POSITION;
				float depth : TEXCOORD0;
			};

			float _range;
			float4 _color;
			
			float inverse_lerp (float a, float b, float t)
			{
				return (t - a)/(b - a);
			}
			
			structure vertex_shader (float4 vertex:POSITION)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				float d = distance(mul (unity_ObjectToWorld, vertex).xyz,_WorldSpaceCameraPos.xyz);
				vs.depth = inverse_lerp(0.0,_range,d);
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float t = ps.depth;
				return float4(t*_color.rgb,_color.a);
			}

			ENDCG

		}
	}
}
