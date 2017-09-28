//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
Shader "Oren-Nayar lightmodel"
{
	Properties
	{
		roughness("Roughness",Range(0.0,1.0)) = 0.5
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float roughness;
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
			
			float4 cuboid (float3 p,float3 c,float3 s)
			{
				float3 m = float3(1.0,1.0,0.0);
				float3 d = abs(p-c)-s;
				return float4(m,max(max(d.x,d.y),d.z));
			}
			
			float substraction( float d1, float d2 )
			{
				return max(-d1,d2);
			}		
			
			float4 map (float3 p)
			{
				float solid=substraction(cuboid(p,float3(0.0,0.0,0.0),float3(1.0,1.0,6.0)).w,cuboid(p,float3(0.0,0.0,0.0),float3(2.0,2.0,2.0)).w);
				solid=substraction(cuboid(p,float3(0.0,0.0,0.0),float3(1.0,6.0,1.0)).w,solid);
				solid=substraction(cuboid(p,float3(0.0,0.0,0.0),float3(6.0,1.0,1.0)).w,solid);
				return float4(float3(1.0,0.0,0.0),solid);
			}
			
			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x).w-map(p-x).w, map(p+y).w-map(p-y).w, map(p+z).w-map(p-z).w)); 
			}

			float3 oren_nayar(float3 rd, float3 ld, float3 n)
			{
				float3 col = float3(0.0,0.0,0.0);
				float NdotL = dot(n, ld);
				float NdotV = dot(-rd, n);
				float angleVN = acos(NdotV);
				float angleLN = acos(NdotL);
				float mu = roughness;
				float A = 1.0-0.5*mu*mu/(mu*mu+0.57);
				float B = 0.45*mu*mu/(mu*mu+0.09);
				float alpha = max(angleVN, angleLN);
				float beta = min(angleVN, angleLN);
				float gamma = dot(-rd -(n * NdotV), ld - (n * NdotL));
				float albedo = 1.1;
				float e0 = 3.1;
				float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * sin(alpha) * tan(beta));
				return float3(1.0,1.0,1.0) * L1;
			}
			
			float3 lighting (float3 p, float3 rd)
			{
				float3 AmbientLight = float3 (0.5,0.5,0.5);
				float3 LightDirection = normalize(float3 (4.0,10.0,-10.0));
				float3 LightColor = float3 (0.0,0.0,1.0);
				float3 NormalDirection = set_normal(p);
				return oren_nayar (rd,LightDirection,NormalDirection);			
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float ray = map(ro).w;
					float3 material = map(ro).xyz;
					if (ray < 0.001) return float4 (lighting(ro,rd)*material,1.0); else ro+=ray*rd; 
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