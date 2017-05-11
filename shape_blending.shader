//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Play.
Shader "Shape blending"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			static float time = abs(sin(_Time.g));
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};

			float sphere (float3 p,float3 c,float r)
			{
				return length (p-c)-r;
			}

			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return max(max(d.x,d.y),d.z);
			}

			float4 rasterize (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				float4 AmbientLight = float4 (1.0,0.0,0.0,0.0);
				float4 LightDirection = normalize(float4 (4.0,10.0,-10.0,1.0));
				float4 LightColor = float4 (0.0,1.0,1.0,1.0);
				float3 NormalDirection = normalize(float3( 
					lerp(sphere(p+x,0,1),cuboid(p+x,0,1),time) - lerp(sphere(p-x,0,1),cuboid(p-x,0,1),time),
					lerp(sphere(p+y,0,1),cuboid(p+y,0,1),time) - lerp(sphere(p-y,0,1),cuboid(p-y,0,1),time),
					lerp(sphere(p+z,0,1),cuboid(p+z,0,1),time) - lerp(sphere(p-z,0,1),cuboid(p-z,0,1),time))); 
				float4 DiffuseColor = saturate (dot(LightDirection, NormalDirection)) * LightColor + AmbientLight;
				return DiffuseColor;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = lerp (sphere(ro,0,1),cuboid(ro,0,1),time);
					if (t < 0.01) return rasterize (ro);
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
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos);
				return raymarch (worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}