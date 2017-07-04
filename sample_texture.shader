Shader "Sample Texture"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			float3x3 rotation( float x ) 
			{
				return float3x3
				(
					1.0,0.0,0.0,
					0.0,cos(x),-sin(x),
					0.0,sin(x),cos(x)
				);
			}	
			
			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return float(max(max(d.x,d.y),d.z));
			}
					
			float map (float3 p)
			{
			  p = mul(rotation(_Time.g ),p);
				return cuboid(p,float3(0.0,0.0,0.0),float3(1.0,1.0,1.0));
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float3 set_texture( float3 pos, float3 nor )
			{
				float3 w = nor*nor;
				return (w.x*tex2Dlod(_MainTex,float4(pos.yz,0.0,0.0) ) + w.y*tex2Dlod(_MainTex,float4(pos.zx,0.0,0.0))+ w.z*tex2Dlod(_MainTex,float4(pos.xy,0.0,0.0)) / (w.x+w.y+w.z)); 
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