//source : https://www.shadertoy.com/view/MdX3Rr

Shader "Elevated"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			#define SC (5.0)

			float rand(float2 n) 
			{ 
				return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
			}

			float3 noised(float2 x )
			{
				float2 f = frac(x);
				float2 u = f*f*(3.0-2.0*f);
				float2 p = floor(x);
				float a = rand (p + float2(0.0,0.0));
				float b = rand (p + float2(1.0,0.0));
				float c = rand (p + float2(0.0,1.0));
				float d = rand (p + float2(1.0,1.0));				
				return float3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
					6.0*f*(1.0-f)*(float2(b-a,c-a)+(a-b-c+d)*u.yx));
			}

			static const float2x2 m2 = float2x2(0.8,-0.6,0.6,0.8);

			float terrainH( float2 x )
			{
				float2  p = x*0.003/SC;
				float a = 0.0;
				float b = 1.0;
				float2  d = float2(0.0,0.0);
				for( int i=0; i<15; i++ )
				{
					float3 n = noised(p);
					d += n.yz;
					a += b*n.x/(1.0+dot(d,d));
					b *= 0.5;
					p = p*2.0;
					p = mul(p,m2);
				}
				return SC*120.0*a;
			}

			float terrainM( float2 x )
			{
				float2  p = x*0.003/SC;
				float a = 0.0;
				float b = 1.0;
				float2 d = float2(0.0,0.0);
				for( int i=0; i<9; i++ )
				{
					float3 n = noised(p);
					d += n.yz;
					a += b*n.x/(1.0+dot(d,d));
					b *= 0.5;
					p = p*2.0;
					p = mul(p,m2);
				}
				return SC*120.0*a;
			}

			float terrainL( float2 x )
			{
				float2  p = x*0.003/SC;
				float a = 0.0;
				float b = 1.0;
				float2  d = float2(0.0,0.0);
				for( int i=0; i<3; i++ )
				{
					float3 n = noised(p);
					d += n.yz;
					a += b*n.x/(1.0+dot(d,d));
					b *= 0.5;
					p = p*2.0;
					p = mul(p,m2);
				}
				return SC*120.0*a;
			}

			float interesct(float3 ro,float3 rd,float tmin,float tmax )
			{
				float t = tmin;
				for( int i=0; i<256; i++ )
				{
					float3 pos = ro + t*rd;
					float h = pos.y - terrainM( pos.xz );
					if( h<(0.002*t) || t>tmax ) break;
					t += 0.3*h;
				}
				return t;
			}

			float softShadow(float3 ro,float3 rd )
			{
				float res = 1.0;
				float t = 0.001;
				for( int i=0; i<80; i++ )
				{
					float3  p = ro + t*rd;
					float h = p.y - terrainM( p.xz );
					res = min( res, 16.0*h/t );
					t += h;
					if( res<0.001 ||p.y>(SC*200.0) ) break;
				}
				return clamp( res, 0.0, 1.0 );
			}

			float3 calcNormal(float3 pos, float t )
			{
				float2 eps = float2( 0.002*t, 0.0 );
				return normalize( float3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
					2.0*eps.x,terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
			}

			float fbm( float2 p )
			{
				float f = 0.0;
				f += 0.5000*noised(p).x; p = p*2.02; p = mul(p,m2);
				f += 0.2500*noised(p).x; p = p*2.03; p = mul(p,m2);
				f += 0.1250*noised(p).x; p = p*2.01; p = mul(p,m2);
				f += 0.0625*noised(p).x;
				return f/0.9375;
			}

			static const float kMaxT = 5000.0*SC;

			float4 render( in float3 ro, in float3 rd )
			{
				float3 light1 = normalize( float3(-0.8,0.4,-0.3) );
				float tmin = 0.5;
				float tmax = kMaxT;

				float sundot = clamp(dot(rd,light1),0.0,1.0);
				float3 col;
				float t = interesct( ro, rd, tmin, tmax );
				if( t>tmax)
				{	
					col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
					col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
					col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
					col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
					col += 0.2*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
					float2 sc = ro.xz + rd.xz*(SC*1000.0-ro.y)/rd.y;
					col = lerp( col, float3(1.0,0.95,1.0), 0.5*smoothstep(0.5,0.8,fbm(0.0005*sc/SC)) );
					col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
					t = -1.0;
				}
				else
				{
					float3 pos = ro + t*rd;
					float3 nor = calcNormal( pos, t );
					float3 ref = reflect( rd, nor );
					float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
					float r = noised((7.0/SC)*pos.xz/256.0 ).x;
					col = (r*0.25+0.75)*0.9*lerp( float3(0.08,0.05,0.03), float3(0.10,0.09,0.08), 
												 noised(0.00007*float2(pos.x,pos.y*48.0)/SC).x );
					col = lerp( col, 0.20*float3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
					col = lerp( col, 0.15*float3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );
					float h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
					float e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
					float o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
					float s = h*e*o;
					col = lerp( col, 0.29*float3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );		
					float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
					float dif = clamp( dot( light1, nor ), 0.0, 1.0 );
					float bac = clamp( 0.2 + 0.8*dot( normalize( float3(-light1.x, 0.0, light1.z ) ), nor ), 0.0, 1.0 );
					float sh = 1.0; if( dif>=0.0001 ) sh = softShadow(pos+light1*SC*0.05,light1);		
					float3 lin  = float3(0.0,0.0,0.0);
					lin += dif*float3(7.00,5.00,3.00)*1.3*float3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
					lin += amb*float3(0.40,0.60,0.80)*1.2;
					lin += bac*float3(0.40,0.50,0.60);
					col *= lin;        
					col += s*0.1*pow(fre,4.0)*float3(7.0,5.0,3.0)*sh * pow( clamp(dot(light1,ref), 0.0, 1.0),16.0);
					col += s*0.1*pow(fre,4.0)*float3(0.4,0.5,0.6)*smoothstep(0.0,0.6,ref.y);
					float fo = 1.0-exp(-pow(0.001*t/SC,1.5) );
					float3 fco = 0.65*float3(0.4,0.65,1.0);// + 0.1*float3(1.0,0.8,0.5)*pow( sundot, 4.0 );
					col = lerp( col, fco, fo );

				}
				col += 0.3*float3(1.0,0.7,0.3)*pow( sundot, 8.0 );
				col = sqrt(col);   
				return float4( col, 1.0 );
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
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return render (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}