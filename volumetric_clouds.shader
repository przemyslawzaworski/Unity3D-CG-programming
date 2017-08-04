// source: https://www.shadertoy.com/view/4sSBDG and https://www.shadertoy.com/view/XslGRr
//In Unity3D editor, add quad to Main Camera. Bind material with shader to the quad. Set quad position at (0.0,0.0,0.4) and camera position at (0.0,0.0,30.0). Play.
Shader "Volumetric clouds"
{

	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
						
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};	
			
			float hash( float n )
			{
				return frac(sin(n)*43758.5453);
			}

			float noise( in float3 x )
			{
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0-2.0*f);
				float n = p.x + p.y * 57.0 + 113.0 * p.z;
				float res = lerp(lerp(lerp( hash(n+  0.0), hash(n+  1.0),f.x),
					lerp( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
					lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
					lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
				return res;
			}

			float fbm( float3 p )
			{
				float3 q = p - float3(0.0,0.1,1.0)*_Time.g*0.2;
				float f;
				f  = 0.50000*noise( q ); q = q*2.02;
				f += 0.25000*noise( q ); q = q*2.03;
				f += 0.12500*noise( q ); q = q*2.01;
				f += 0.06250*noise( q ); q = q*2.02;
				f += 0.03125*noise( q );
				return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 30.0 );
			}

			float scene(float3 p)
			{	
				return 0.2 - length(p) * .05 + fbm(p*.3);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{				
				float4 color = float4(0,0,0,0);
				float3 dir = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				const int nbSample = 128;
				const int nbSampleLight = 6;	
				float zMax = 160.0;
				float step = zMax/float(nbSample);
				float zMaxl = 20.0;
				float stepl = zMaxl/float(nbSampleLight);
				float3 p = ps.world_vertex;
				float T = 1.0;
				float absorption = 100.0;
				float3  sun_direction = normalize( float3(0.0,1.0,-1.0) );	
				for(int i=0; i<nbSample; i++)
				{
					float density = scene(p);
					if(density>0.0)
					{
						float tmp = density / float(nbSample);
						T *= 1. - tmp * absorption;
						if( T <= 0.01) break;
						float Tl = 1.0;
						for(int j=0; j < nbSampleLight; j++)
						{
							float densityLight = scene( p + normalize(sun_direction) * float(j) * stepl);
							if(densityLight > 0.0) Tl *= 1.0-densityLight*absorption/float(nbSample);
							if (Tl <= 0.01) break;
						}
						color += 50. * tmp * T + 80. * tmp * T * Tl;
					}        
					p += dir * step;
				}    	
				return  color;
			}

			ENDCG

		}
	}
}