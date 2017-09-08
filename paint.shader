Shader "Paint"
{
	Properties
	{
		[HideInInspector]
		iMouse("iMouse",Vector) = (-1.0,-1.0,0.0,0.0)
		brush("Brush Color",Color) = (1,1,1,1)
		size("Brush Size",Range(0.001,0.050)) = 0.005
		[KeywordEnum(Circle,Circle2,Rect)] shapes("Brush shapes", Float) = 0
		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
			
			float4 iMouse;
			float4 brush;
			float size;
			float shapes;
			
			float4 vertex_shader (float4 vertex:POSITION):SV_POSITION
			{
				return UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (float4 vertex:SV_POSITION):SV_TARGET
			{
				float2 uv=vertex.xy/_ScreenParams.xy;
				switch(shapes)
				{
					case 0:
						{
							float circle=length(iMouse.xy-uv.xy);
							if (circle>size) discard;
							return brush;
						}
					case 1:
						{
							float circle=length(iMouse.xy-uv.xy);
							circle = smoothstep(circle,size-0.002,size);
							if (circle>size) discard;
							return brush;
						}
					case 2:
						{
							float2 rect = abs(iMouse.xy-uv.xy);
							if (any(rect>size)) discard;
							return brush;
						}						
					default:
							return float4(0,0,0,1);
				}

			}
			ENDCG
		}
	}
}