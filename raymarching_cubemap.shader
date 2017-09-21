//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;).
// Apply fly script to the camera and cubemap to material. Play.
Shader "Raymarching Cubemap"
{
	Properties 
	{
		_Cube("Environment Map", Cube) = "" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			uniform samplerCUBE _Cube;

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
						
			float sphere (float3 p,float3 c,float r)
			{
				return distance(p,c)-r;
			}

			float map (float3 p)
			{
				return sphere(p,float3(0,0,0),2.0);
			}

			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.000,0.000);
				float3 y = float3 (0.000,0.001,0.000);
				float3 z = float3 (0.000,0.000,0.001);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<64; i++)
				{
					float t = map(ro);
					if (t < 0.001)
					{	
						rd=reflect(rd,set_normal(ro));
						return texCUBElod(_Cube,float4(rd,0.0)); 
					}
					else ro+=t*rd;  
				}
				return texCUBE(_Cube,rd);
			}

			custom_type vertex_shader (float4 vertex:POSITION)
			{
				custom_type vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul(unity_ObjectToWorld,vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ):SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex-_WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}