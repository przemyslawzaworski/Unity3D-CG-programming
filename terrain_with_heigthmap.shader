// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Heightmap should be in high resolution (1024x1024 or better) and be blurred to avoid artifacts. Set Main Camera to following position (0,50,0).
Shader "Terrain with heightmap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			sampler2D _MainTex;
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};	
								
			float map (float3 p)
			{
				return p.y-32.0*tex2Dlod(_MainTex,float4(p.xz*0.005,0.0,0.0)).g;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<512; i++)
				{
					float t = map(ro);
					float c = tex2Dlod(_MainTex,float4(ro.xz*0.005,0.0,0.0)).g;
					if (ro.x>100.0 || ro.x<-100.0 || ro.z>100.0 || ro.z<-100.0) break;
					if ( t<0.0001 && ro.y<6.0) return float4(0.0,0.0,1.0-1.0/ro.y,1.0);
					if ( t<0.0001 && ro.y>=6.0) return float4(3.0/ro.y,0.0,0.0,1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.0,0.0);
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
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}