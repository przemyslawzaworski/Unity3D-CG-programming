Shader "Triangle 2" 
{
	SubShader 
	{
		Cull Off
		Tags {"RenderType"="Opaque"}
		Pass 
		{                     
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
						
			struct structure 
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float Triangle(float2 p0,float2 p1,float2 p2,float2 p )
			{
				float2 e0 = p1 - p0;
				float2 e1 = p2 - p1;
				float2 e2 = p0 - p2;
				float2 v0 = p - p0;
				float2 v1 = p - p1;
				float2 v2 = p - p2;
				float2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
				float2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
				float2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );   
				float s = sign( e0.x*e2.y - e0.y*e2.x );
				float2 d = min( min( float2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
					float2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
					float2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
				return -sqrt(d.x)*sign(d.y);
			}
			
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos( vertex );			
				vs.uv = uv;
				return vs;
			}
			
			float4 pixel_shader (structure ps) : COLOR 
			{
				float2 uv = ps.uv.xy;
				float2 v1 = float2(0.1,0.7);
				float2 v2 = float2(0.3,0.3);
				float2 v3 = float2(0.6,0.6);
				float d = Triangle( v1, v2, v3, uv );
				float3 col = float3(0.8,0.9,0.5) ;
				float3 col1 = lerp( col, float3(0.0,0.0,0.0), 1.0-smoothstep(0.0,0.01,abs(d)));
				float3 col2 = lerp( col, float3(1.0,0.0,0.0), 1.0-smoothstep(0.0,0.005,(d)));
				float3 col3 = min(col1,col2);
				return float4(col3,1.0);
			}
			ENDCG
		}
	}
}