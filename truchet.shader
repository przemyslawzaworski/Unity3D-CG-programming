Shader "Truchet"
{
	Properties
	{
		_scaleX("UV.X scale", Range (1.0,20.0)) = 18.0
		_scaleY("UV.Y scale", Range (1.0,20.0)) = 18.0
		color1 ("Color 1", Color) = (0,1,0,1)
		color2 ("Color2", Color) = (1,0,0,1)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float _scaleX,_scaleY;
			float4 color1,color2;
			
			float pattern(float2 p)
			{
				float2 h = p + float2(0.58, 0.15)*p.y; 
				float2 f = frac(h);  
				h -= f;
				float v = frac((h.x + h.y) / 3.0);
				if (v<0.6 && v>=0.3) h++;
				if (v>=0.6) h+=step(f.yx,f); 
				p += float2(0.5, 0.13)*h.y - h;          
				v = sign(cos(1234.*cos(h.x+9.*h.y)));
				return 0.1 / abs(0.5 -  min(min
					(length(p - v*float2(-1., 0.00)  ),    
					 length(p - v*float2(0.5, 0.87)) ),    
					 length(p - v*float2(0.5,-0.87))));    
			} 
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 uv = ps.uv.xy;
				uv.x*=_scaleX; uv.y*=_scaleY;    
				return lerp(color1, color2, pattern (uv)); 		
			}
			ENDCG
		}
	}
}