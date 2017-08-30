//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
Shader "Raymarching Point Lights"
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
						
			float4 sphere (float3 p,float3 c,float r)
			{
				float3 m = float3 (1.0,1.0,1.0);
				return float4 (m,length(p-c)-r);
			}
					
			float4 map (float3 p)
			{
				return sphere(p,float3(0,0,0),2.0);
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.000,0.000);
				float3 y = float3 (0.000,0.001,0.000);
				float3 z = float3 (0.000,0.000,0.001);
				return normalize(float3(map(p+x).w-map(p-x).w,map(p+y).w-map(p-y).w,map(p+z).w-map(p-z).w)); 
			}

			float3 point_light (float3 p,float4 LP, float3 LC)
			{
				float4 LightPosition = LP;  //X,Y,Z,range
				float3 LightDirection = float3 (LightPosition.xyz - p);
				float LightLength = length (LightDirection);
				LightDirection = normalize(LightDirection);
				float Attenuation = 1.0 - pow(min(1.0,LightLength/LightPosition.w),2.0);
				float3 LightColor = LC;
				float3 NormalDirection = set_normal(p);
				return max(dot(LightDirection,NormalDirection),0.0)*Attenuation*LightColor;			
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight =float3 (0.0,0.0,0.0);
				float3 light01 = point_light(p,float4(0.0,0.0,-10.0,12.0),float3(0,0,0.7));
				float3 light02 = point_light(p,float4(-10.0,0.0,0.0,12.0),float3(0.8,0,0));
				float3 light03 = point_light(p,float4(10.0,0.0,0.0,25.0),float3(0,0.5,0));
				return light01+light02+light03+AmbientLight;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = map(ro).w;
					float3 material = map(ro).xyz;
					if (ray < 0.001) return float4 (lighting(ro)*material,1.0); else ro+=ray*rd; 
				}
				return float4 (0.0,0.0,0.0,1.0);
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