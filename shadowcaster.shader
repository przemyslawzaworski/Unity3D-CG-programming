//Rendering shapes of shadow independently from main geometry

Shader "ShadowCaster"
{
	Subshader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float4 vertex_shader (float4 vertex:POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (void) : COLOR
			{
				return 0;
			}
			
			ENDCG
		}

		Pass
		{		
			Tags{ "LightMode" = "ShadowCaster" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			float hash(float n)
			{
				return frac(sin(n)*43758.5453123);
			}
					
			float4 vertex_shader (float4 vertex:POSITION,uint id:SV_VertexID, float3 normal:NORMAL) : SV_POSITION
			{
				vertex.xyz-=(sin(_Time.g)*0.5+0.5)*normal*hash(float(id));
				return UnityObjectToClipPos(vertex);								
			}

			float4 pixel_shader (void) : COLOR
			{
				return 0;
			}
			ENDCG
		}
	}
}