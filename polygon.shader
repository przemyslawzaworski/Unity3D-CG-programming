Shader "Polygon"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			
			static const float2 vertices[4] = {{0.2f,0.6f},{0.7f,0.2f},{0.8f,0.5f},{0.4f,0.7f}};
			
			float polygon( float2 v[4], float2 p )
			{
				const int num = 4;
				float d = dot(p-v[0],p-v[0]);
				float s = 1.0;
				for( int i=0, j=num-1; i<num; j=i, i++ )
				{
					float2 e = v[j] - v[i];
					float2 w = p - v[i];
					float2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
					d = min( d, dot(b,b) );
					vector <bool,3> cond = { p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x };
					if( all(cond) || all(!(cond)) ) s*=-1.0;
				}   
				return s*sqrt(d);
			}

			void VSMain (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex:POSITION,float2 uv:TEXCOORD0) : SV_TARGET
			{
				float d = polygon(vertices, uv);
				float3 k = step(sign(d),float3(0.0,0.0,0.0));
				return float4(k,1);
			}
			ENDCG
		}
	}
}