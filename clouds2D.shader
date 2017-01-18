//Original source https://www.shadertoy.com/view/4tdSWr
//Translated from GLSL to CG by Przemyslaw Zaworski
Shader "Clouds 2D"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct v2f
			{
				float4 screen_space_vertex : sv_position;
			};

			static const float cloudscale = 1.1;
			static const float speed = 0.03;
			static const float clouddark = 0.5;
			static const float cloudlight = 0.3;
			static const float cloudcover = 0.2;
			static const float cloudalpha = 8.0;
			static const float skytint = 0.5;
			static const float3 skycolour1 = float3(0.2, 0.4, 0.6);
			static const float3 skycolour2 = float3(0.4, 0.7, 1.0);
			static const float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );

			float2 hash( float2 p ) 
			{
				p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
				return -1.0 + 2.0*frac(sin(p)*43758.5453123);
			}

			float noise( float2 p ) 
			{
			    const float K1 = 0.366025404; 
			    const float K2 = 0.211324865; 
				float2 i = floor(p + (p.x+p.y)*K1);	
			    float2 a = p - i + (i.x+i.y)*K2;
			    float2 o = (a.x>a.y) ? float2(1.0,0.0) : float2(0.0,1.0);
			    float2 b = a - o + K2;
				float2 c = a - 1.0 + 2.0*K2;
			    float3 h = max(0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
				float3 n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
			    return dot(n, float3(70.0,70.0,70.0));	
			}

			float fbm(float2 n) 
			{
				float total = 0.0, amplitude = 0.1;
				for (int i = 0; i < 7; i++) 
				{
					total += noise(n) * amplitude;
					n = mul(m,n);
					amplitude *= 0.4;
				}
				return total;
			}

			v2f vertex_shader (float4 local_vertex:POSITION)
			{
				v2f o;
				o.screen_space_vertex = mul(UNITY_MATRIX_MVP,local_vertex);
				return o;
			}

			float4 pixel_shader (v2f z) : COLOR
			{
				float2 p = z.screen_space_vertex.xy / _ScreenParams.xy;
				float2 uv = p * float2 (_ScreenParams.x / _ScreenParams.y, 1.0); 
	    		float time = _Time.g * speed;
	    		float q = fbm(uv * cloudscale * 0.5);   
				float r = 0.0;
				uv *= cloudscale;
			    uv -= q - time;
			    float weight = 0.8;
			    for (int i=0; i<8; i++)
			    {
					r += abs(weight*noise( uv ));
			        uv = mul(m,uv) + time;
					weight *= 0.7;
			    }

				float f = 0.0;
			    uv = p*float2(_ScreenParams.x/_ScreenParams.y,1.0);
				uv *= cloudscale;
			    uv -= q - time;
			    weight = 0.7;
			    for (int ii=0; ii<8; ii++)
			    {
					f += weight*noise( uv );
			        uv = mul(m,uv) + time;
					weight *= 0.6;
			    }
			    
			    f *= r + f;

			    float c = 0.0;
			    time = _Time.g * speed * 2.0;
			    uv = p*float2(_ScreenParams.x/_ScreenParams.y,1.0);
				uv *= cloudscale*2.0;
			    uv -= q - time;
			    weight = 0.4;
			    for (int iii=0; iii<7; iii++)
			    {
					c += weight*noise( uv );
			        uv = mul(m,uv) + time;
					weight *= 0.6;
			    }

			    float c1 = 0.0;
			    time = _Time.g * speed * 3.0;
			    uv = p*float2(_ScreenParams.x/_ScreenParams.y,1.0);
				uv *= cloudscale*3.0;
			    uv -= q - time;
			    weight = 0.4;
			    for (int iiii=0; iiii<7; iiii++)
			    {
					c1 += abs(weight*noise( uv ));
			        uv = mul(m,uv) + time;
					weight *= 0.6;
			    }
				
			    c += c1;		    
			    float3 skycolour = lerp(skycolour2, skycolour1, p.y);
			    float3 cloudcolour = float3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight*c), 0.0, 1.0);			   
			    f = cloudcover + cloudalpha*f*r;			    
			    float3 result = lerp(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));			    
				return float4( result, 1.0 );
			}

			ENDCG
		}
	}
}