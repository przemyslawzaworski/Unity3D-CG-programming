//In Unity3D editor, add quad to Main Camera. Set quad position (0.0;0.0;0.4) and camera position(0,0,-2). Bind material with shader to the quad. Add fly script to the camera. Play.
//source : https://www.shadertoy.com/view/4dl3Wl
Shader "Sierpinski"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			static const float3 va = float3(  0.0,  0.57735,  0.0 );
			static const float3 vb = float3(  0.0, -1.0,  1.15470 );
			static const float3 vc = float3(  1.0, -1.0, -0.57735 );
			static const float3 vd = float3( -1.0, -1.0, -0.57735 );	
			static const float precis = 0.0002;
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};	

			float2 map( float3 p )
			{
				float a = 0.0;
				float s = 1.0;
				float r = 1.0;
				float dm;
				float3 v;
				for( int i=0; i<8; i++ )
				{
					float d, t;
					d = dot(p-va,p-va);              v=va; dm=d; t=0.0;
					d = dot(p-vb,p-vb); if( d<dm ) { v=vb; dm=d; t=1.0; }
					d = dot(p-vc,p-vc); if( d<dm ) { v=vc; dm=d; t=2.0; }
					d = dot(p-vd,p-vd); if( d<dm ) { v=vd; dm=d; t=3.0; }
					p = v + 2.0*(p - v); r*= 2.0;
					a = t + 4.0*a; s*= 4.0;
				}				
				return float2( (sqrt(dm)-1.0)/r, a/s );
			}

			float3 intersect( in float3 ro, in float3 rd )
			{
				float3 res = float3( 1e20, 0.0, 0.0 );				
				float maxd = 5.0;
				float h = 1.0;
				float t = 0.5;
				float m = 0.0;
				float2 r;
				for( int i=0; i<100; i++ )
				{
					r = map( ro+rd*t );
					if( r.x<precis || t>maxd ) break;
					m = r.y;
					t += r.x;
				}
				if( t<maxd && r.x<precis ) res = float3( t, 2.0, m );
				return res;
			}

			float3 calcNormal( in float3 pos )
			{
				float3 eps = float3(precis,0.0,0.0);
				return normalize( float3(
					   map(pos+eps.xyy).x - map(pos-eps.xyy).x,
					   map(pos+eps.yxy).x - map(pos-eps.yxy).x,
					   map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
			}

			float calcOcclusion( in float3 pos, in float3 nor )
			{
				float ao = 0.0;
				float sca = 1.0;
				for( int i=0; i<8; i++ )
				{
					float h = 0.001 + 0.5*pow(float(i)/7.0,1.5);
					float d = map( pos + h*nor ).x;
					ao += -(d-h)*sca;
					sca *= 0.95;
				}
				return clamp( 1.0 - 0.8*ao, 0.0, 1.0 );
			}

			float3 render( in float3 ro, in float3 rd )
			{
				float3 col = float3(0.0,0.0,0.0);
				float3 lig = normalize(float3(1.0,0.7,0.9));
				float3 tm = intersect(ro,rd);
				if( tm.y>0.5 )
				{
					float3 pos = ro + tm.x*rd;
					float3 nor = calcNormal( pos );
					float3 maa = float3( 0.0,0.0,0.0 );					
					maa = 0.5 + 0.5*cos( 6.2831*tm.z + float3(0.0,1.0,2.0) );
					float occ = calcOcclusion( pos, nor );
					float amb = (0.5 + 0.5*nor.y);
					float dif = max(dot(nor,lig),0.0);
					float3 lin = 1.5*amb*float3(1.0,1.0,1.0) * occ;
					col = maa * lin;					
				}
				return col;
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
				return float4(render (worldPosition,viewDirection),1.0);
			}

			ENDCG

		}
	}
}