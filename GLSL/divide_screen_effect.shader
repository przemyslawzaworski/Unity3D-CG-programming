//https://www.shadertoy.com/view/XlfyWB
Shader "Divide Screen Effect" 
{ 
	SubShader 
	{ 
		Pass 
		{ 
			GLSLPROGRAM 

			uniform vec4 _Time;
			
			#ifdef VERTEX 
				varying vec2 texcoord;
				void main()
				{
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
					texcoord = gl_MultiTexCoord0.xy;
				}
			#endif 

			const float lineScale = 40.0;
			
			float Color(vec2 pos)
			{
				float radius = atan(pos.x, pos.y);
				float num = abs(pos.x) + abs(pos.y);
				float line = floor(num * lineScale);
				float speed = sin(line * 24.3);
				float offset = fract(sin(speed));  
				return step(.4,tan(radius+offset+speed*(_Time.y+5.0)))*offset;  
			} 
			
			#ifdef FRAGMENT 
				varying vec2 texcoord;
				void main()
				{
					vec2 uv = 2.0*texcoord-1.0;  
					gl_FragColor = vec4(Color(uv),Color(uv-0.003),Color(uv),1.0);
				}
			#endif
			
			ENDGLSL 
		}
	}
}