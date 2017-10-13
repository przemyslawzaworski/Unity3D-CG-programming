//usage: like other examples...
Shader "Raymarching repetition"
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

			float sphere (float3 p,float3 c,float r)
			{
				return length (p-c)-r;
			}
			
			float3 repetition (float3 p)
			{
				float3 a = float3(fmod(p.x,3.0)-1.5, p.y, fmod(p.z,10.0)-5.0);
				float3 b = float3(-fmod(p.x,3.0)-1.5, p.y, -fmod(p.z,10.0)-5.0);
				return max(a,b);
			}
			
			float map(float3 p)
			{
				float3 q = repetition(p);
				return sphere(q,float3(0,0,0),1.0);
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float4 lighting (float3 p)
			{
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = float3(1,1,1);
				float3 NormalDirection = set_normal(p);
				return float4(max(dot(LightDirection, NormalDirection),0.0)*LightColor+AmbientLight,1.0);
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.01) return lighting(ro);
					ro+=t*rd;
				}
				return 0;
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
				float3 viewDirection = normalize(ps.world_vertex-_WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}