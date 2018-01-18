//Add quad to Main Camera, then add volume_texture.cs to quad and material with shader (both to script and Mesh Renderer). 
//Set quad position to (0,0,0.4). Play.

Shader "Volume Texture"
{
	Properties 
	{
		[HideInInspector]
		volume ("Texture 3D", 3D) = "black" {}
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler3D volume;
			
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD0;
			};

			structure vertex_shader (float4 vertex:POSITION) 
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				return vs;
			}

			float4 pixel_shader (structure ps) : SV_TARGET
			{
				float3 ro = ps.world_vertex;
				float3 rd = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);  
				float4 s = float4(0.0,0.0,0.0,0.0);
				for (float t = 1.0; t < 32.0; t++) 
				{
					ro+=rd*t;
					s+=tex3Dlod(volume,float4(ro*.002,0))*.06;
					if (s.w >= 1.0) break;
				}    
				return lerp(float4(0.0,0.0,0.0,0.0),s,s.w);				
			}
			ENDCG
		}
	}
}