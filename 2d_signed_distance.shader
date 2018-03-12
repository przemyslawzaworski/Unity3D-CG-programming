Shader "2D signed distance"
{
	Properties
	{
		_size ("Size", Range(0.0, 1.0)) = 0.5
		_smoothness ("Smoothness", Range(0.0, 0.1)) = 0.03
		_color ("Color ", Color) = (1,1,1,1)
		_edges ("Number of edges", Int) = 3
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
		
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			int _edges;
			float _size,_smoothness;
			float4 _color;
			
			void vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				float3 color = float3(0.0,0.0,0.0);
				float d = 0.0;
				float a = atan2(uv.x,uv.y)+3.14159265359;
				float r = 6.28318530718/float(_edges);
				d = cos(floor(0.5+a/r)*r-a)*length(uv);
				float k = 1.0-smoothstep(_size,_size+_smoothness,d);
				color = float3(k,k,k)*_color;
				fragColor = float4(color,1.0);
			}
			ENDCG
		}
	}
}