Shader "Sphere Mapping"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		X("UV.X scale",Range(0.00,2.0)) = 1.0
		Y("UV.Y scale",Range(0.00,2.0)) = 1.0		
	}
	Subshader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Pass
		{
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float4 _LightColor0;
			sampler2D _MainTex;
			float X,Y;
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
			
			float4 sphere (float3 p,float3 c,float r)
			{
				return length(p-c)-r;
			}
					
			float map (float3 p)
			{
				return sphere(p,float3(0,0,0),1.0);
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float3 set_texture( float3 d, float3 nor )
			{
				float2 p = float2(acos(d.y/length(d)), atan2(d.z,d.x))*float2(X,Y); 
				return tex2Dlod(_MainTex,float4(p,0,0)).xyz;
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.xyz;
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight)*set_texture(p,NormalDirection);;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (distance(ro,t*rd)>250) break;
					if (t < 0.001) return float4 (lighting(ro),1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.0,0.0);
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