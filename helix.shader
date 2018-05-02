Shader "Helix"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
			
			struct SHADERDATA
			{
				float4 gl_Position : SV_POSITION;
				float3 vertex : TEXCOORD0;
			};

			float mod(float x, float y)
			{
				return x - y * floor(x/y);
			}

			float map (float3 q)
			{
				float r = 20.0;
				float a = atan2(q.z,q.x); 
				q.x = length(q.xz)-r;  
				q.y = mod(q.y-a*r/6.28,r)-r*0.5;
				q.z = r*a;    
				float l = length(q.xy);
				float d = sin(atan2(q.y,q.x)-q.z);
				return length(float2(l-4.0,d)) - 0.5;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0;i<128;i++)
				{
					float t = map (ro);
					if (t<0.001)
					{
						float c = pow(1.0-float(i)/float(128),2.0);
						return float4(c,c,c,1.0);     
					}		
					ro+=t*rd;
				}
				discard;
				return float4(0,0,0,1);
			}
			
			SHADERDATA vertex_shader (float4 vertex:POSITION)
			{
				SHADERDATA vs;
				vs.gl_Position = UnityObjectToClipPos (vertex);
				vs.vertex = mul(unity_ObjectToWorld, vertex);
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps ) : SV_TARGET
			{		
				float3 ro = ps.vertex;
				float3 rd = normalize(ps.vertex - _WorldSpaceCameraPos.xyz);				
				return raymarch(ro,rd);
			}

			ENDCG

		}
	}
}