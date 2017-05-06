//Original source https://www.shadertoy.com/view/llKXzh
//Translated from GLSL to CG by Przemyslaw Zaworski
Shader "ApollonianII"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			sampler2D _MainTex;
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			float3 map (float3 p)
			{
				float scale = 1.0;		    
			    float orb = 10000.0;
			    for( int i=0; i<6; i++ )
				{
					p = -1.0 + 2.0*frac(0.5*p+0.5);
			        p -= sign(p)*0.04; 			        
			        float r2 = dot(p,p);
					float k = 0.95/r2;
					p *= k;
					scale *= k;
			        orb = min( orb, r2);
				}
			    float d1 = sqrt( min( min( dot(p.xy,p.xy), dot(p.yz,p.yz) ), dot(p.zx,p.zx) ) ) - 0.02;
			    float d2 = abs(p.y);
			    float dmi = d2;
			    float adr = 0.7*floor((0.5*p.y+0.5)*8.0);
			    if( d1<d2 )
			    {
			        dmi = d1;
			        adr = 0.0;
			    }
			    return float3( 0.5*dmi/scale, adr, orb );
			}

			float3 trace( in float3 ro, in float3 rd )
			{
				float maxd = 20.0;
			    float t = 0.01;
			    float2  info = float2(0.0,0.0);
			    for( int i=0; i<256; i++ )
			    {
				    float precis = 0.001*t;			        
			        float3  r = map( ro+rd*t );
				    float h = r.x;
			        info = r.yz;
			        if( h<precis||t>maxd ) break;
			        t += h;
			    }
			    t=lerp(-1.0,t,step(t,maxd));
			    return float3( t, info );
			}

			float3 calcNormal( in float3 pos, in float t )
			{
			    float precis = 0.0001 * t * 0.57;
			    float2 e = float2(1.0,-1.0)*precis;
			    return normalize (e.xyy*map( pos + e.xyy ).x + e.yyx*map( pos + e.yyx ).x + e.yxy*map( pos + e.yxy ).x + e.xxx*map( pos + e.xxx ).x);
			}

			float3 forwardSF( float i, float n) 
			{
			    const float PI  = 3.141592653589793238;
			    const float PHI = 1.618033988749894848;
			    float phi = 2.0*PI*frac(i/PHI);
			    float zi = 1.0 - (2.0*i+1.0)/n;
			    float sinTheta = sqrt( 1.0 - zi*zi);
			    return float3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
			}

			float calcAO( in float3 pos, in float3 nor )
			{
				float ao = 0.0;
			    for( int i=0; i<16; i++ )
			    {
			        float3 w = forwardSF( float(i), 16.0 );
					w *= sign( dot(w,nor) );
			        float h = float(i)/15.0;
			        ao += clamp( map( pos + nor*0.01 + w*h*0.15 ).x*2.0, 0.0, 1.0 );
			    }				
			    return clamp (ao, 0.0, 1.0 );
			}

			float3 textureBox( sampler2D sam, in float3 pos, in float3 nor )
			{
			    float3 w = nor*nor;
			    return (w.x*tex2D( sam, pos.yz ).xyz +  w.y*tex2D( sam, pos.zx ).xyz + w.z*tex2D( sam, pos.xy ).xyz ) / (w.x+w.y+w.z);
			}

			float3 render( in float3 ro, in float3 rd )
			{
			    float3 col = float3(0.0,0.0,0.0);
			    float3 res = trace( ro, rd );;
			    float t = res.x;
			    if( t>0.0 )
			    {
			        float3  pos = ro + t*rd;
			        float3  nor = calcNormal( pos, t );
			        float fre = clamp(1.0+dot(rd,nor),0.0,1.0);
			        float occ = pow( clamp(res.z*2.0,0.0,1.0), 1.2 );
			        occ = 1.5*(0.1+0.9*occ)*calcAO(pos,nor);        
			        float3  lin = float3(1.0,1.0,1.5)*(2.0+fre*fre*float3(1.8,1.0,1.0))*occ*(1.0-0.5*abs(nor.y));			        
			      	col = 0.5 + 0.5*cos( 6.2831*res.y + float3(0.0,1.0,2.0) );  
			        col *= textureBox( _MainTex, pos, nor ).xyz;
			        col = col*lin;
			        col += 0.6*pow(1.0-fre,32.0)*occ*float3(0.5,1.0,1.5);        
			        col *= exp(-0.3*t);
			    }
			    col.z += 0.01;
			    return sqrt(col);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.world_vertex = mul(_Object2World, vertex).xyz;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos);
        		return float4 (render( worldPosition, viewDirection ),1.0);
			}

			ENDCG
		}
	}
}