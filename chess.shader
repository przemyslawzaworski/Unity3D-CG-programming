//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
Shader "Chess"
{
	Properties
	{
		draw("Draw distance",Float)= 300
		field("Field size",Float)= 0.2
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float draw, field;
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			float plane(float3 p)
			{
				return p.y;
			}

			float3 chess (float2 uv)
			{
				float d = field;
				float x = fmod( floor(uv.x*d), 2.0 );
				float y = fmod( floor(uv.y*d), 2.0 );
				return ( ( abs(x)==0.0 && abs(y)==0.0) ||  ( abs(x)==1.0 && abs(y)==1.0) ) ? float3 (1.0,1.0,1.0): float3(0.0,0.0,0.0);				
			}
			
			float3 set_texture( float3 pos, float3 nor )
			{
				float3 w = nor*nor;
				return (w.x*chess(pos.yz ) + w.y*chess(pos.zx)+ w.z*chess(pos.xy)) / (w.x+w.y+w.z); 
			}
			
			float3 rasterize (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				float3 AmbientLight = float3 (0.1,0.1,0.1);
				float3 LightDirection = normalize(float3 (4.0,10.0,-10.0));
				float3 LightColor = float3 (1.0,1.0,1.0);
				float3 NormalDirection = normalize(float3( 
					plane(p+x) - plane (p-x),
					plane(p+y) - plane (p-y),
					plane(p+z) - plane (p-z) )); 
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight)*set_texture(p,NormalDirection);
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = plane(ro);
					if (t < 0.001) return float4 (rasterize (ro),1.0);
					if (distance(ro,t*rd)>draw) break;
					ro+=t*rd;
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
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}