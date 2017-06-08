//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
//references: http://www.iquilezles.org/www/articles/smin/smin.htm   https://www.shadertoy.com/view/Xds3zN
Shader "Abstract"
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
						
			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return float(max(max(d.x,d.y),d.z));
			}			
							
			float smin( float a, float b, float k )
			{
				float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
				return lerp( b, a, h ) - k*h*(1.0-h);
			}
						
			float map (float3 p)
			{
				return max(smin(cuboid(p,float3(0,0,0),float3(3,1,3)),cuboid(p,float3(0,1,0),float3(1,1,1)),2.0),-cuboid(p,float3(0,abs(sin(_Time.g))+2,0),float3(1,1,1)));
			}
			
			float ambient_occlusion( float3 pos, float3 nor )
			{
				float occ = 0.0;
				float sca = 1.0;
				for( int i=0; i<5; i++ )
				{
					float hr = 0.01 + 0.12*float(i)/4.0;
					float3 aopos =  nor * hr + pos;
					float dd = map( aopos );
					occ += -(dd-hr)*sca;
					sca *= 0.95;
				}
				return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
			}
						
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.00,0.00);
				float3 y = float3 (0.00,0.001,0.00);
				float3 z = float3 (0.00,0.00,0.001);
				return normalize(float3(map(p+x)-map(p-x), map(p+y)-map(p-y), map(p+z)-map(p-z))); 
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight = float3 (0.1,0.1,0.1);
				float3 LightDirection = normalize(float3 (4.0,10.0,-10.0));
				float3 LightColor = float3 (1.0,1.0,1.0);
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight)*ambient_occlusion(p,NormalDirection);
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = map(ro);
					if (distance(ro,ray*rd)>250) break;
					if (ray < 0.001) return float4 (lighting(ro)*float3(1.0,0.0,0.0),1.0); else ro+=ray*rd; 
				}
				return float4 (0.0,0.0,0.0,1.0);
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