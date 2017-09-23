//source: https://www.shadertoy.com/view/MsdGzl
//Run Unity3D editor in OpenGL mode: Unity.exe with parameter -force-glcore
//Simple path tracing with diffuse lighting. Excluded progressive rendering (need additional pass and render texture).
//Add 3D object/Quad to Main Camera. Set quad position (0,0,0,4). Apply material with shader to the quad.
//Include fly script to Main Camera from: https://forum.unity.com/threads/fly-cam-simple-cam-script.67042/
Shader "Basic Montecarlo" 
{ 
	SubShader 
	{ 
		Pass 
		{ 
			GLSLPROGRAM 
			uniform vec4 _ScreenParams;
			uniform vec4 _Time;
			uniform mat4 _Object2World;
			uniform vec4 _WorldSpaceCameraPos;
			
			#ifdef VERTEX 
				varying vec4 world_vertex;
				void main()
				{
					gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
					world_vertex=unity_ObjectToWorld * gl_Vertex;
				}
			#endif 

			#ifdef FRAGMENT 
				varying vec4 world_vertex;

				float hash(float seed)
				{
					return fract(sin(seed)*43758.5453 );
				}

				vec3 cosineDirection( in float seed, in vec3 nor)
				{
					float u = hash( 78.233 + seed);
					float v = hash( 10.873 + seed);
					float ks = (nor.z>=0.0)?1.0:-1.0;     
					float ka = 1.0 / (1.0 + abs(nor.z));
					float kb = -ks * nor.x * nor.y * ka;
					vec3 uu = vec3(1.0 - nor.x * nor.x * ka, ks*kb, -ks*nor.x);
					vec3 vv = vec3(kb, ks - nor.y * nor.y * ka * ks, -nor.y); 
					float a = 6.2831853 * v;
					return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
				}

				float maxcomp(in vec3 p ) { return max(p.x,max(p.y,p.z));}

				float sdBox( vec3 p, vec3 b )
				{
				  vec3  di = abs(p) - b;
				  float mc = maxcomp(di);
				  return min(mc,length(max(di,0.0)));
				}

				float map (vec3 p)
				{
					vec3 w = p;
					vec3 q = p;
					q.xz = mod( q.xz+1.0, 2.0 )-1.0;   
					float d = sdBox(q,vec3(1.0));
					float s = 1.0;
					for( int m=0; m<6; m++ )
					{
						float h = float(m)/6.0;
						p =  q - 0.5*sin( abs(p.y) + float(m)*3.0+vec3(0.0,3.0,1.0));
						vec3 a = mod( p*s, 2.0 )-1.0;
						s *= 3.0;
						vec3 r = abs(1.0 - 3.0*abs(a));
						float da = max(r.x,r.y);
						float db = max(r.y,r.z);
						float dc = max(r.z,r.x);
						float c = (min(da,min(db,dc))-1.0)/s;
						d = max( c, d );
					}   
					float d1 = length(w-vec3(0.22,0.35,0.4)) - 0.09;
					d = min( d, d1 );
					float d2 = w.y + 0.22;
					d =  min( d,d2);  
					return d;
				}

				vec3 calcNormal( in vec3 pos )
				{
					vec3 eps = vec3(0.0001,0.0,0.0);
					return normalize( vec3(
						map( pos+eps.xyy ) - map( pos-eps.xyy ),
						map( pos+eps.yxy ) - map( pos-eps.yxy ),
						map( pos+eps.yyx ) - map( pos-eps.yyx ) ));
				}

				float intersect( vec3 ro, vec3 rd )
				{
					float res = -1.0;
					float tmax = 16.0;
					float t = 0.01;
					for(int i=0; i<128; i++ )
					{
						float h = map(ro+rd*t);
						if( h<0.0001 || t>tmax ) break;
						t +=  h;
					}   
					if( t<tmax ) res = t;
					return res;
				}

				float shadow( in vec3 ro, in vec3 rd )
				{
					float res = 0.0;   
					float tmax = 12.0;
					float t = 0.001;
					for(int i=0; i<80; i++ )
					{
						float h = map(ro+rd*t);
						if( h<0.0001 || t>tmax) break;
						t += h;
					}
					if( t>tmax ) res = 1.0;
					return res;
				}

				vec3 sunDir = normalize(vec3(-0.3,1.3,0.1));
				vec3 sunCol =  6.0*vec3(1.0,0.8,0.6);
				vec3 skyCol =  4.0*vec3(0.2,0.35,0.5);

				vec3 calculateColor(vec3 ro, vec3 rd, float sa )
				{
					const float epsilon = 0.0001;
					vec3 colorMask = vec3(1.0);
					vec3 accumulatedColor = vec3(0.0);
					float fdis = 0.0;
					for( int bounce = 0; bounce<5; bounce++ ) 
					{
						float t = intersect( ro, rd );
						if( t < 0.0 )
						{
							if( bounce==0 ) return mix(0.05*vec3(0.9,1.0,1.0),skyCol,smoothstep(0.1,0.25,rd.y));
							break;
						}
						if( bounce==0 ) fdis = t;
						vec3 pos = ro + rd * t;
						vec3 nor = calcNormal( pos );
						vec3 surfaceColor = vec3(0.4)*vec3(1.2,1.1,1.0);
						colorMask *= surfaceColor;
						vec3 iColor = vec3(0.0);       
						float sunDif =  max(0.0, dot(sunDir, nor));
						float sunSha = 1.0; if( sunDif > 0.00001 ) sunSha = shadow( pos + nor*epsilon, sunDir);
						iColor += sunCol * sunDif * sunSha;
						vec3 skyPoint = cosineDirection(sa+7.1*float(_Time.g*100.0)+5681.123+float(bounce)*92.13,nor);
						float skySha = shadow( pos + nor*epsilon, skyPoint);
						iColor += skyCol * skySha;
						accumulatedColor += colorMask * iColor;
						rd = cosineDirection(76.2 + 73.1*float(bounce) + sa + 17.7*float(_Time.g*100.0),nor);
						ro = pos;
					}
					float ff = exp(-0.01*fdis*fdis);
					accumulatedColor *= ff; 
					accumulatedColor += (1.0-ff)*0.05*vec3(0.9,1.0,1.0);
					return accumulatedColor;
				}

				void main()
				{
					float sa = hash( dot(gl_FragCoord.xy,vec2(12.9898,78.233))+1113.1*float(_Time.g*100.0));
					vec3 ro = world_vertex.xyz;
					vec3  rd = normalize(world_vertex.xyz-_WorldSpaceCameraPos.xyz);  
					vec3 col = calculateColor( ro, rd, sa );
					gl_FragColor = vec4(col,1.0);
				}
				
			#endif 
			ENDGLSL 
		}
	}
}