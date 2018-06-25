Shader "Map Projection" 
{
	SubShader 
	{
		Pass 
		{                     
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
						
			uniform extern float4 pointA, pointB, pointC, pointD, pointE, pointF;
			uniform extern sampler2D Projection;
			uniform extern float4x4 _matrix;
			uniform extern float4 colorIN;
			uniform extern float cornerAX,cornerAY,cornerBX,cornerBY; 
			
			float2 InverseLerp (float2 x, float2 a, float2 b)
			{
				return (x-a)/(b-a); 
			}
			
			float Triangle(float2 p0,float2 p1,float2 p2,float2 p )
			{
				float2 e0 = p1 - p0;
				float2 e1 = p2 - p1;
				float2 e2 = p0 - p2;
				float2 v0 = p - p0;
				float2 v1 = p - p1;
				float2 v2 = p - p2;
				float2 pq0 = v0 - e0*saturate( dot(v0,e0)/dot(e0,e0));
				float2 pq1 = v1 - e1*saturate( dot(v1,e1)/dot(e1,e1));
				float2 pq2 = v2 - e2*saturate( dot(v2,e2)/dot(e2,e2));   
				float s = sign( e0.x*e2.y - e0.y*e2.x );
				float2 d = min( min( float2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
					float2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
					float2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
				return -sqrt(d.x)*sign(d.y);
			}
			
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0) 
			{
				vertex = UnityObjectToClipPos( vertex );			
			}
			
			float4 pixel_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0) : COLOR 
			{
				float2 borderA = float2(cornerAX,cornerAY);
				float2 borderB = float2(cornerBX,cornerBY);
				float2 v1 = InverseLerp (mul(_matrix,pointA).xz,borderA,borderB);
				float2 v2 = InverseLerp (mul(_matrix,pointB).xz,borderA,borderB);
				float2 v3 = InverseLerp (mul(_matrix,pointC).xz,borderA,borderB);
				float2 v4 = InverseLerp (mul(_matrix,pointD).xz,borderA,borderB);
				float2 v5 = InverseLerp (mul(_matrix,pointE).xz,borderA,borderB);
				float2 v6 = InverseLerp (mul(_matrix,pointF).xz,borderA,borderB);					
				float d1 = Triangle( v1, v2, v3, uv );
				float d2 = Triangle( v4, v5, v6, uv );
				float3 colA = (1.0-smoothstep(0.0,0.005,(d1))) * colorIN;
				float3 colB = (1.0-smoothstep(0.0,0.005,(d2))) * colorIN;
				float3 color;
				if (sign(d1)==0.0 || sign(d2)==0.0) 
					color = 0;
				else
					color = max(colA,colB);
				color+=tex2D(Projection,uv).rgb;
				return float4(color,1.0);
			}
			ENDCG
		}
	}
}