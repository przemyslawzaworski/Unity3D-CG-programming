Shader "Raymarching room"
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
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
		
			static float time = sin(_Time.g)*0.5+0.5;
			
			float4 plane (float3 p, float4 n, float3 m)
			{
				return float4(m,dot(p,n.xyz) + n.w);
			}
			
			float4 sphere (float3 p,float3 c,float r, float3 m)
			{
				return float4(m,length (p-c)-r);
			}
					
			float4 map (float3 p)
			{		
				float4 up = plane (p,float4(0.0,-1.0,0.0,20.0),float3(0.0,0.5,0.0));
				float4 down = plane (p,float4(0.0,1.0,0.0,10.0),float3(0.0,0.5,0.0));
				float4 left = plane(p,float4(1.0,0.0,0.0,20.0),float3(1.0,1.0,0.0));
				float4 right = plane (p,float4(-1.0,0.0,0.0,20.0),float3(1.0,1.0,0.0));
				float4 front = plane(p,float4(0.0,0.0,1.0,20.0),float3(0.0,0.0,1.0));
				float4 back = plane(p,float4(0.0,0.0,-1.0,20.0),float3(0.0,0.0,1.0));			
				float4 room = lerp(up,down,step(down.w,up.w));
				room = lerp (room,left,step(left.w,room.w));
				room = lerp (room,right,step(right.w,room.w));
				room = lerp (room,front,step(front.w,room.w)); 
				room = lerp (room,back,step(back.w,room.w)); 
				return  lerp (room,sphere(p,float3(0.0,0.0,0.0),2.0,float3(1.0,1.0,1.0)),step(sphere(p,float3(0.0,0.0,0.0),2.0,float3(1.0,1.0,1.0)).w,room.w));
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x).w-map(p-x).w,map(p+y).w-map(p-y).w,map(p+z).w-map(p-z).w)); 
			}
			
			float soft_shadow ( float3 ro, float3 rd, float mint, float maxt, float k )
			{
				float t = mint;
				float res = 1.0;
				for ( int i = 0; i < 128; ++i )
				{
					float h = map(ro + rd * t).w;
					if ( h < 0.001 ) return 0.0;
					res = min( res, k * h / t );
					t += h;
					if ( t > maxt ) break;
				}
				return res;
			}

			float3 lighting (float3 p, float3 ViewDirection)
			{	
				float3 Material = map(p).xyz;
				float3 LightPosition = float3( 4.0, 5.0, -10.0 );
				LightPosition .x = cos( _Time.g * 0.5 ) * 8.0;
				LightPosition .z = sin( _Time.g * 0.5 ) * 8.0;
				float3 LightDirection  = LightPosition - p;
				float LightDistance= length( LightDirection  );
				LightDirection  = normalize( LightDirection );
				float Shadow = soft_shadow( p, LightDirection , 0.0625, LightDistance,32.0);
				float3 AmbientDiffuseLight = float3 (0.0,0.0,0.0);
				float3 AmbientSpecularLight = float3 (0.1,0.1,0.1);
				float3 LightColor = float3 (1.0,1.0,1.0);
				float3 SpecularBase = float3 (1.0,1.0,1.0);
				float SpecularSpread = 50.0;
				float SpecularPower = 1.0;
				float3 NormalDirection = set_normal(p);
				float3 HalfVector = normalize(LightDirection-ViewDirection);
				float3 DiffuseColor = max (dot(LightDirection , NormalDirection),0.0) * LightColor * Material;
				float3 SpecularColor = pow(clamp (dot(HalfVector, NormalDirection),0.0,1.0),SpecularSpread) * SpecularPower * SpecularBase;
				return lerp((DiffuseColor+SpecularColor+AmbientSpecularLight),(DiffuseColor+AmbientDiffuseLight)*Shadow,step(dot(Material,Material),2.99));
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = map(ro).w;				
					if (distance(ro,ray*rd)>50) break;
					if (ray < 0.001) return  float4(lighting(ro,rd),1.0); else ro+=ray*rd; 
				}
				clip(-1);
				return float4(0.0,0.0,0.0,1.0);
			}

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP, vertex);
				vs.world_vertex = mul (_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}