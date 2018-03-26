Shader "Outline" 
{
	Properties 
	{
		_Color ("Mesh color", Color) = (0,0,1,1)
		[Toggle] _enable("Outline enable", Float) = 1
		_outline_thickness ("Outline thickness", Float ) = 0.05
		_outline_color ("Outline color", Color) = (0,0,0,1)
	}
	SubShader 
	{
		Tags {"RenderType"="Opaque"}
		Pass 
		{
			Name "Outline"
			Cull Front   
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			float _outline_thickness,_enable;
			float4 _outline_color;
            				
			float4 vertex_shader (float4 vertex:POSITION,float3 normal:NORMAL):SV_POSITION
			{
				return UnityObjectToClipPos(float4(vertex.xyz+normal*_outline_thickness,1));
			}
            
			float4 pixel_shader(float4 vertex:SV_POSITION):COLOR 
			{
				if (_enable==1)
				{
					return float4(_outline_color.rgb,0);
				}
				else
				{
					discard;
					return 0;
				}						
			}          
			ENDCG
		}
        
		Pass 
		{
			Name "FORWARD"
			Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
				
			float4 _Color;
												
			float4 vertex_shader (float4 vertex:POSITION):SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}
				
			float4 pixel_shader(float4 vertex:SV_POSITION):COLOR 
			{
				return _Color;
			}
			ENDCG
		}
	}
}
