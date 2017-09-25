//reference: http://www.geeks3d.com/20111111/simple-introduction-to-geometry-shaders-glsl-opengl-tutorial-part1/
//Minimal exercise. You should see blue color.
//Pass-through geometry shader sends the input primitives (a triangle) to the rasterizer without transformation.

Shader "Geometry Shader #01" 
{ 
	SubShader 
	{ 
		Pass 
		{ 
			GLSLPROGRAM 
			
			#ifdef VERTEX 
				void main()
				{
					gl_Position = gl_ModelViewProjectionMatrix*gl_Vertex;
				}
			#endif 
			
			#ifdef GEOMETRY
				layout(triangles) in;
				layout(triangle_strip, max_vertices=3) out;
				void main()
				{
					for(int i=0; i<3; i++)
					{
						gl_Position = gl_in[i].gl_Position;
						EmitVertex();
					}
					EndPrimitive();
				}	
			#endif
					
			#ifdef FRAGMENT 
				out vec4 color;
				void main()
				{
					color = vec4(0.0, 0.0, 1.0, 1.0);
				}
			#endif
			
			ENDGLSL 
		}
	}
}