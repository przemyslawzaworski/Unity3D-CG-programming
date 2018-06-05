Shader "Maze"
{
	Properties
	{
		_scale ("Scale", Range(1.0,60.0)) = 30
		_hash ("Seed", Range(500.0,2000.0)) = 1000
		_color ("Color", Color) = (1.0,0.0,0.0,1.0)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			float _scale, _hash;
			float4 _color;
			
			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{	
				float2 uv = ps.uv * _scale;
				float hash = sin(12345.67*sin(_hash*length(ceil(uv))));	
				float pattern = cos(3.14159265*(uv.y+uv.x*sign(hash)));
				return  _color / pattern;
			}

			ENDCG

		}
	}
}