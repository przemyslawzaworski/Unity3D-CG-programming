//Original source https://www.shadertoy.com/view/4d2XWV
//Translated from GLSL to CG by Przemyslaw Zaworski
Shader "Soft Shadows"
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
				float4 screen_space_position : sv_position;
				float2 uv : TEXCOORD0;
			};

			float sphIntersect( in float3 ro, in float3 rd, in float4 sph )
			{
				float3 oc = ro - sph.xyz;
				float b = dot( oc, rd );
				float c = dot( oc, oc ) - sph.w*sph.w;
				float h = b*b - c;
				if( h<0.0 ) return -1.0;
				return -b - sqrt( h );
			}


			float sphSoftShadow( in float3 ro, in float3 rd, in float4 sph, in float k )
			{
			    float3 oc = ro - sph.xyz;
			    float b = dot( oc, rd );
			    float c = dot( oc, oc ) - sph.w*sph.w;
			    float h = b*b - c;
			    float d = sqrt( max(0.0,sph.w*sph.w-h)) - sph.w;
			    float t = -b - sqrt( max(h,0.0) );
			    return (t<0.0) ? 1.0 : smoothstep(0.0, 1.0, 2.5*k*d/t );
			}    
            
			float sphOcclusion( in float3 pos, in float3 nor, in float4 sph )
			{
			    float3  r = sph.xyz - pos;
			    float l = length(r);
			    return dot(nor,r)*(sph.w*sph.w)/(l*l*l);
			}

			float3 sphNormal( in float3 pos, in float4 sph )
			{
			    return normalize(pos-sph.xyz);
			}

			float2 hash2( float n ) 
			{ 
				return frac(sin(float2(n,n+1.0))*float2(43758.5453123,22578.1459123)); 
			}

			float iPlane( in float3 ro, in float3 rd )
			{
			    return (-1.0 - ro.y)/rd.y;
			}


			v2f vertex_shader (float4 local_space_position:POSITION,float2 uv:texcoord0)
			{
				v2f o;
				o.screen_space_position = mul (UNITY_MATRIX_MVP, local_space_position);
				o.uv=uv;
				return o;
			}

			float4 pixel_shader (v2f i ) : SV_TARGET
			{
				float2 p = (2.0*i.screen_space_position.xy-_ScreenParams.xy) / _ScreenParams.y; 
				p.y=0.0-p.y;
				float3 ro = float3 (0.0,0.0, 6.0);
				float3 rd = normalize( float3(p,-2.0) );
			    float4 sph = float4( cos( float3(2.0,1.0,1.0) + 0.0 )*float3(1.5,0.0,1.0), 1.0 );
				sph.x = 1.0;    
			    float3 lig = normalize( float3(0.6*cos(_Time.g),0.3,0.4) );
			    float3 col = float3(0.0,0.0,0.0);
			    float tmin = 10000000000.0;
			    float3 nor;
			    float occ = 1.0;
			    float t1 = iPlane( ro, rd );
			    if( t1>0.0 )
			    {
			        tmin = t1;
			        float3 pos = ro + t1*rd;
			        nor = float3(0.0,1.0,0.0);
			        occ = 1.0-sphOcclusion( pos, nor, sph );
			    }

			    float t2 = sphIntersect( ro, rd, sph );
			    if( t2>0.0 && t2<tmin )
			    {
			        tmin = t2;
			        float3 pos = ro + t2*rd;
			        nor = sphNormal( pos, sph );
			        occ = 0.5 + 0.5*nor.y;
				}

			    if( tmin<1000.0 )
			    {
			        float3 pos = ro + tmin*rd; 
					col = float3(1.0,1.0,1.0);
			        col *= clamp( dot(nor,lig), 0.0, 1.0 );
			        col *= sphSoftShadow( pos, lig, sph, 2.0 );
			        col += 0.05*occ;
				    col *= exp( -0.05*tmin );
			    }

			    col = sqrt(col);
			    return float4( col, 1.0 );
			}

			ENDCG

		}
	}
}