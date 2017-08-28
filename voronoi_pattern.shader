//source: https://www.shadertoy.com/view/MslGD8
Shader "Voronoi Pattern"
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float2 hash (float2 p) 
			{
				p=float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3)));
				return frac(sin(p)*18.5453); 
			}

			float2 voronoi (float2 x)
			{
				float2 n = floor(x);
				float2 f = frac(x);
				float3 m = float3(8,8,8);
				for( int j=-1; j<=1; j++ )
				for( int i=-1; i<=1; i++ )
				{
					float2  g = float2( float(i), float(j) );
					float2  o = hash( n + g );
					float2  r = g - f + (0.5+0.5*sin(6.2831*o));
					float d = dot( r, r );
					if( d<m.x )  m = float3( d, o );
				}
				return float2( sqrt(m.x), m.y+m.z );
			}
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 p = ps.uv.xy;
				float2 c = voronoi(20.0*p);
				float3 col = 0.5+0.5*cos(c.y*6.2831+float3(0.0,1.0,2.0));		
				return float4(col,1.0);			
			}
			ENDCG
		}
	}
}