//references:
//http://code4k.blogspot.com/2011/11/advanced-hlsl-using-closures-and.html
//https://www.shadertoy.com/view/lscGRl

Shader "Fireworks"
{
	Properties
	{
		_explosions ("Explosions amount", Int) = 5	
		_particles ("Particles amount", Int) = 100		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			int _explosions, _particles;

			class seed
			{
				static float3 hash(float p) 
				{
					return frac(sin(float3(p*127.1,p*269.5,p*419.2))*43758.5453);
				}
			};

			float3 explosion(float2 uv, float2 p, float s, float t) 
			{
				float3 color = 0;   
				float3 k = seed::hash(s);
				float3 base = k;
				for(int i=0; i<_particles; i++) 
				{
					float3 n = seed::hash(float(i))-0.5; 
					float2 a = p-float2(0.0,t*t*0.1);        
					float2 b = a+normalize(n.xy)*n.z;
					float pt = 1.0-pow(t-1.0, 2.0);
					float2 pos = lerp(p, b, pt);    
					float size = lerp(0.01, 0.005, smoothstep(0.0, 0.1, pt)) * smoothstep(1.0, 0.1, pt);   
					float sparkle = (sin((pt+n.z)*100.0)*0.5+0.5);
					sparkle = pow(sparkle, pow(k.x, 3.0)*50.0)*lerp(0.01, 0.01, k.y*n.y);
					size += sparkle*smoothstep(k.x-k.z,k.x+k.z,t)*smoothstep(k.y+k.z,k.y-k.z,t) ;
					color += base*size*size/dot(uv-pos, uv-pos);
				}   
				return color;
			}
			
			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{	
				float2 uv = ps.uv;  
				float3 c = 0;
				for(int i=0; i<_explosions; i++) 
				{
					float t = _Time.g*0.5+float(i)*1234.45235;
					float id = floor(t);     
					float2 p = seed::hash(id).xy;
					//p.x = (p.x-0.5)*1.5;
					c += explosion(uv, p, id, t-id);
				}    
				return float4(c, 1.0);
			}

			ENDCG

		}
	}
}