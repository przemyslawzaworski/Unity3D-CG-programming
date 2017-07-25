//source: https://www.shadertoy.com/view/MdfGRX
//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Play.
Shader "Hell"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
			
			float hash (float n)
			{ 
				return frac(sin(n)*43758.5453); 
			}
			
			float noise ( float3 x ) 
			{ 
				float3 p = floor(x);
				float3 f = frac(x);
				f = f*f*(3.0-2.0*f);
				float n = p.x + p.y*57.0 + 113.0*p.z;
				return lerp(lerp(lerp(hash(n+0.0 ),hash(n+1.0),f.x),lerp(hash(n+57.0),hash(n+58.0),f.x),f.y),lerp(lerp(hash(n+113.0),hash(n+114.0),f.x),lerp(hash(n+170.0),hash(n+171.0),f.x),f.y),f.z);
			}

			float4 map( float3 p )
			{
				float den = 0.2 - p.y;
				p = -7.0*p/dot(p,p);
				float co = cos(den - 0.25*_Time.g);
				float si = sin(den - 0.25*_Time.g);
				p.xz = mul(p.xz,float2x2(co,-si,si,co));	
				float f;
				float3 q = p - float3(0.0,1.0,0.0)*_Time.g;
				f  = 0.50000*noise( q ); q = q*2.02 - float3(0.0,1.0,0.0)*_Time.g;
				f += 0.25000*noise( q ); q = q*2.03 - float3(0.0,1.0,0.0)*_Time.g;
				f += 0.12500*noise( q ); q = q*2.01 - float3(0.0,1.0,0.0)*_Time.g;
				f += 0.06250*noise( q ); q = q*2.02 - float3(0.0,1.0,0.0)*_Time.g;
				f += 0.03125*noise( q );
				den = clamp( den + 4.0*f, 0.0, 1.0 );	
				float3 col = lerp( float3(1.0,0.9,0.8), float3(0.4,0.15,0.1), den ) + 0.05*sin(p);	
				return float4( col, den );
			}

			float3 raymarch(float3 ro, float3 rd, float2 pixel )
			{
				float4 sum = float4( 0.0 ,0.0,0.0,0.0);
				float t = 0.0;
				t+=0.05*noise(float3(pixel*sqrt(_Time.g),frac(_Time.g)));
				for( int i=0; i<100; i++ )
				{
					if( sum.a > 0.99 ) break;		
					float3 pos = ro + t*rd;
					float4 col = map( pos );		
					col.xyz *= lerp( 3.1*float3(1.0,0.5,0.05), float3(0.48,0.53,0.5), clamp((pos.y-0.2)/2.0, 0.0, 1.0 ) );		
					col.a *= 0.6;
					col.rgb *= col.a;
					sum = sum + col*(1.0 - sum.a);	
					t += 0.05;
				}
				return clamp( sum.xyz, 0.0, 1.0 );
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
				float2 q = ps.screen_vertex.xy / _ScreenParams.xy;
				float2 p = -1.0 + 2.0*q;
				p.x *= _ScreenParams.x/ _ScreenParams.y;
				float2 mo = float2(0.0,0.0);
				float3 ro = 4.0*normalize(float3(cos(3.0*mo.x), 1.4 - 1.0*(mo.y-.1), sin(3.0*mo.x)));
				float3 ta = float3(0.0,1.0,0.0);
				float cr = 0.5*cos(0.7*_Time.g);
				float3 ww = normalize( ta - ro);
				float3 uu = normalize(cross( float3(sin(cr),cos(cr),0.0), ww ));
				float3 vv = normalize(cross(ww,uu));
				float3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
				float3 col = raymarch( ro, rd, ps.screen_vertex.xy );
				col = col*0.5 + 0.5*col*col*(3.0-2.0*col);
				col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );	
				return float4( col, 1.0 );
			}

			ENDCG

		}
	}
}