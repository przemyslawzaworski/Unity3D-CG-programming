Shader "Raycasting cylinder"
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

			float4 cylinder(float3 ro,float3 rd, float3 pa,float3 pb, float ra) 
			{
				float3 cc = 0.5*(pa+pb);
				float ch = length(pb-pa);
				float3 ca = (pb-pa)/ch;
				ch *= 0.5;
				float3  oc = ro - cc;
				float card = dot(ca,rd);
				float caoc = dot(ca,oc);				
				float a = 1.0 - card*card;
				float b = dot( oc, rd) - caoc*card;
				float c = dot( oc, oc) - caoc*caoc - ra*ra;
				float h = b*b - a*c;
				if( h<0.0 ) return float4(-1,-1,-1,-1);
				h = sqrt(h);
				float t1 = (-b-h)/a;
				float y = caoc + t1*card;
				if( abs(y)<ch ) return float4(t1,normalize(oc+t1*rd-ca*y));			
				float sy = sign(y);
				float tp = (sy*ch - caoc)/card;
				if( abs(b+a*tp)<h ) return float4( tp, ca*sy );
				else return float4(-1,-1,-1,-1);
			}

			float4 raycast (float3 ro, float3 rd)
			{
				float4 tnor = cylinder(ro,rd,float3(-0.2,-0.3,-0.1),float3(0.3,0.3,0.4),0.3 );
				float t = tnor.x;	
				if( t>0.0 )
				{
					float3 pos = ro + t*rd;
					float3 nor = tnor.yzw;
					float dif = clamp( dot(nor,float3(0.57703,0.57703,0.57703)), 0.0, 1.0 );
					float amb = 0.5 + 0.5*dot(nor,float3(0.0,1.0,0.0));
					return float4(sqrt(float3(0.2,0.3,0.4)*amb+float3(0.8,0.7,0.5)*dif),1.0);
				}
				else return float4(0,0,0,1);
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
				return raycast (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}