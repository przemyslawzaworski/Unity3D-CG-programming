Shader "LabyrinthGLES"
{
	Subshader
	{
		Pass
		{
			GLSLPROGRAM

			#ifdef VERTEX
				#version 320 es
				
				uniform uint _GridSize; 
				uniform highp sampler2D _Texture;
				out highp vec4 worldPos;

				const vec3 _Vertices[36] = vec3[36] // vertices of single cube, in local space
				(
					vec3( 0.5, -0.5,  0.5), vec3( 0.5,  0.5,  0.5), vec3(-0.5,  0.5,  0.5),
					vec3( 0.5, -0.5,  0.5), vec3(-0.5,  0.5,  0.5), vec3(-0.5, -0.5,  0.5),
					vec3( 0.5,  0.5,  0.5), vec3( 0.5,  0.5, -0.5), vec3(-0.5,  0.5, -0.5),
					vec3( 0.5,  0.5,  0.5), vec3(-0.5,  0.5, -0.5), vec3(-0.5,  0.5,  0.5),
					vec3( 0.5,  0.5, -0.5), vec3( 0.5, -0.5, -0.5), vec3(-0.5, -0.5, -0.5),
					vec3( 0.5,  0.5, -0.5), vec3(-0.5, -0.5, -0.5), vec3(-0.5,  0.5, -0.5),
					vec3( 0.5, -0.5, -0.5), vec3( 0.5, -0.5,  0.5), vec3(-0.5, -0.5,  0.5),
					vec3( 0.5, -0.5, -0.5), vec3(-0.5, -0.5,  0.5), vec3(-0.5, -0.5, -0.5),
					vec3(-0.5, -0.5,  0.5), vec3(-0.5,  0.5,  0.5), vec3(-0.5,  0.5, -0.5),
					vec3(-0.5, -0.5,  0.5), vec3(-0.5,  0.5, -0.5), vec3(-0.5, -0.5, -0.5),
					vec3( 0.5, -0.5, -0.5), vec3( 0.5,  0.5, -0.5), vec3( 0.5,  0.5,  0.5),
					vec3( 0.5, -0.5, -0.5), vec3( 0.5,  0.5,  0.5), vec3( 0.5, -0.5,  0.5)
				);

				// read single byte from four-bytes unsigned int number, index must have values from 0 to 3
				uint ReadByteFromUint(uint u32, uint index)
				{
					return (u32 >> (index << 3u)) & 255u;
				}

				// read single bit from single byte, index must have values from 0 to 7
				uint ReadBitFromByte(uint byte, uint index)
				{
					return (byte >> index) & 1u;
				}

				void main()
				{
					uint instance = uint(gl_InstanceID);
					uint u32 = floatBitsToUint(texelFetch(_Texture, ivec2(instance / 32u, 0), 0).r);
					uint byte = ReadByteFromUint(u32, (instance / 8u) % 4u);
					uint bit = ReadBitFromByte(byte, instance % 8u);
					vec3 offset = vec3(instance % _GridSize, 0.0, instance / _GridSize); 
					worldPos = (bit == 1u) ? vec4(_Vertices[gl_VertexID] + offset, 1.0) : vec4(uintBitsToFloat(0x7FC00000u));
					gl_Position = unity_MatrixVP * worldPos;
				}
			#endif

			#ifdef FRAGMENT
				#version 320 es
				
				uniform vec4 _WorldSpaceLightPos0;
				uniform mediump vec4 unity_AmbientSky;
				in highp vec4 worldPos;
				out highp vec4 fragColor;

				void main()
				{
					vec3 dx = dFdx(worldPos.xyz);
					vec3 dy = dFdy(worldPos.xyz);
					vec3 nd = normalize(cross(dy, dx));
					vec3 ld = normalize(_WorldSpaceLightPos0.xyz);
					float diffuse = max(dot(ld, nd), 0.0);
					fragColor = vec4(vec3(diffuse) + unity_AmbientSky.xyz, 1.0);
				}
			#endif
			
			ENDGLSL
		}
	}
}