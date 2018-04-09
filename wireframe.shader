//Shader uses screen-space partial derivatives, works the best with terrain meshes.

Shader "Wireframe"
{
	Properties
	{
		[Header(Settings)] [Toggle] _transparency ("Transparency", Float) = 1					
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
			
			struct structure
			{
				float4 gl_Position : SV_POSITION;
				float3 vertex : TEXCOORD0;
			};

			float _transparency;
			
			structure vertex_shader (float4 vertex:POSITION) 
			{
				structure vs;
				vs.gl_Position = UnityObjectToClipPos (vertex);
				vs.vertex = vertex;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 p = ps.vertex.xz;
				float2 g = abs(frac(p - 0.5) - 0.5) / fwidth(p);
				float s = min(g.x, g.y);
				float4 c =  float4(s,s,s, 1.0);	
				if (c.r<1.0)
					return 1.0-c;
				else
				{
					if (_transparency==1) discard;
					return 0;
				}
			}
			ENDCG
		}
	}
}