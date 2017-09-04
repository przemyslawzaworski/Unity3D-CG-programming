Shader "Octagon"
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
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float Line( float2 p, float2 a, float2 b )
			{
				float2 pa = p-a, ba = b-a;
				float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
				float2 d = pa - ba*h;
				return dot(d,d);
			}

			float Circle( float2 p,float2 a )
			{
				return dot(p-a,p-a);
			}

			void Octagon (in float2 p, out float3 color)
			{
				float t = 0.01;
				const int n = 8;  
				float2 vertices[n]; 
				vertices[0]=float2(0.24,0.60); 
				vertices[1]=float2(0.60,0.24);
				vertices[2]=float2(0.60,-0.24);
				vertices[3]=float2(0.24,-0.60);
				vertices[4]=float2(-0.24,-0.60);
				vertices[5]=float2(-0.60,-0.24);
				vertices[6]=float2(-0.60,0.24);
				vertices[7]=float2(-0.24,0.60);
				float2 d = float2(1.0,1.0); 
				for( int i=0; i<n-1; i++ ) 
				{
					float2 a = vertices[i+0];
					float2 b = vertices[i+1];
					d = min( d, float2(Line( p,a,b ), Circle(p,a) ) );
				}
				d = sqrt( min( d, float2(Line( p,vertices[7],vertices[0]),Circle(p,vertices[7])))); 
				color = float3(0.8,0.8,0.8); 
				color = lerp( color, float3(0.0,0.0,0.0), 1.0-smoothstep(0.0,t,d.x) );  
				color = lerp( color, float3(0.0,0.0,1.0), 1.0-smoothstep(3.0*t,4.0*t,d.y) );
			}
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 p = 2.0*ps.uv.xy-1.0;
				float3 c = float3(0,0,0);
				Octagon(p,c);
				return float4(c,1);	
			}
			ENDCG
		}
	}
}