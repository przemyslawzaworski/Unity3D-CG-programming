//reference: http://madebyevan.com/shaders/curvature/
//It looks the best with high-poly geometry

Shader "Screen Space Curvature Shader"
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
			
			struct structure
			{
				float4 gl_Position : SV_POSITION;
				float3 normal : NORMAL;
				float3 vertex : TEXCOORD0;
			};

			structure vertex_shader (float4 vertex:POSITION, float3 normal:NORMAL)
			{
				structure vs;
				vs.gl_Position = UnityObjectToClipPos (vertex);
				vs.normal = normal;
				vs.vertex = vertex;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{           
				float3 n = normalize(ps.normal);
				float3 dx = ddx(n);
				float3 dy = ddy(n);
				float3 xneg = n - dx;
				float3 xpos = n + dx;
				float3 yneg = n - dy;
				float3 ypos = n + dy;
				float depth = length(ps.vertex);
				float curvature = (cross(xneg,xpos).y-cross(yneg,ypos).x)*4.0/depth;
				return (curvature+0.5);		
			}
			ENDCG
		}
	}
}