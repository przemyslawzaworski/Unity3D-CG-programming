//source: https://www.shadertoy.com/view/4ssXWn
//Shader sorts pixels according to green channel value. Assign quicksort_input.tga to the texture slot.
//The pixels will be sorted from left to right (see quicksort_output.png). Need to fix small artifacts (lines).
Shader "Quicksort" 
{ 
	Properties 
	{
		_MainTex ("Texture Image", 2D) = "white" {} 
	}
	SubShader 
	{ 
		Pass 
		{ 
			GLSLPROGRAM 

			uniform vec4 _ScreenParams;
			uniform sampler2D _MainTex;
			
			#ifdef VERTEX 
				varying vec2 texcoord;
				void main()
				{
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
					texcoord = gl_MultiTexCoord0.xy;
				}
			#endif 
			
			#ifdef FRAGMENT 
				varying vec2 texcoord;
				const int MAXSIZE=1024;
				const vec4 v1 = vec4(1.0);
				const float fMax = float(MAXSIZE);
				const mat4 mMax = mat4(vec4(fMax), vec4(fMax), vec4(fMax),  vec4(fMax));
				float MM = 1.0;
				int accum[16]; 
				vec2 fragCoordNewAPI = vec2(0.0);

				vec4 tex(int x)
				{
					return texture(_MainTex, vec2(x, fragCoordNewAPI.y / MM)/float(MAXSIZE), 0.0);
				}

				void accumValue(float f)
				{
					int i4 = int(floor(f * 15.0));
					for (int i = 0; i < 16; i++) accum[i] += i == i4 ? 1 : 0;
				}

				ivec2 find_Kth(int k)
				{
					bool found = false;
					int value = 0;
					int i;	
					int a = accum[0];
					for (int i = 0; i < 16; i++)
					{
						if (!found)
						{
							value = i;
							if (k < accum[i]) found = true;
							else k -= accum[i];
						}
					}
					return ivec2(value, k);
				}

				vec4 findTexel(int value, int k)
				{
					vec4 texel = vec4(1.0, 0.0, 0.0, 1.0);
					for (int i = 0; i < 1024; i++)
					{
						vec4 v = tex(i);
						int i4 = int(floor(v.g * 15.0));
						if (i4 == value)
						{
							if (k == 0) texel = v;
							k -= 1;
						}
					}
					return texel;
				}

				int getAccum(int n)
				{
					int ret = 100;		
					for (int i = 0; i < 16; i++)
					{
						if (i == n) ret = accum[i];
					}
					return ret;
				}
				
				void main()
				{ 
					vec2 uv = texcoord;
					vec2 texel = uv;
					vec3 pixel = vec3(uv,1.0);
					for (int i = 0; i < 16; i++) accum[i] = 0;	
					fragCoordNewAPI = uv.xy*MAXSIZE;
					gl_FragColor = vec4(0.0);
					for (int i = 0; i < MAXSIZE; i++) accumValue(tex(i).g);
					int k = int(uv.x*MAXSIZE / MM);
					ivec2 order = find_Kth(k);				
					gl_FragColor += findTexel(order.r, order.g);
				}
			#endif
			
			ENDGLSL 
		}
	}
}