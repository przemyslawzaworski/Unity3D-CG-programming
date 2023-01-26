Shader "JumpFlooding3D"
{
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		Blend One OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler3D _Volume;
			float _Alpha;
			float3 _SliceMin, _SliceMax;

			float4 FloatToRGBA( float f )
			{
				uint q = (uint)(f * 256.0 * 256.0 * 256.0 * 256.0);
				uint r = (uint)(q / (256 * 256 * 256) % 256);
				uint g = (uint)((q / (256 * 256)) % 256);
				uint b = (uint)((q / (256)) % 256);
				uint a = (uint)(q % 256);
				return float4(r / 255.0, g / 255.0, b / 255.0, a / 255.0);
			}

			float4 VSMain (float4 vertex : POSITION, out float4 localPos : LOCALPOS, out float3 direction : DIRECTION) : SV_POSITION
			{
				localPos = vertex;
				direction = mul(unity_ObjectToWorld, vertex).xyz - _WorldSpaceCameraPos;
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float4 localPos : LOCALPOS, float3 direction : DIRECTION) : SV_Target
			{
				float3 ro = localPos;
				float3 rd = mul(unity_WorldToObject, float4(normalize(direction), 1));
				float4 result = float4(0, 0, 0, 0);
				int steps = 256;
				float t = 2.0 / float(steps);
				for (int i = 0; i < steps; i++)
				{
					if(max(abs(ro.x), max(abs(ro.y), abs(ro.z))) < 0.500001f)
					{
						float4 voxel = tex3D(_Volume, ro + float3(0.5f, 0.5f, 0.5f));
						float4 color = float4(FloatToRGBA( voxel.w ).rgb, 1.0);
						color.a *= _Alpha;
						bool blend = all(ro > _SliceMin) && all(ro < _SliceMax);
						result.rgb += blend ? (1.0 - result.a) * color.a * color.rgb : 0..xxx;
						result.a += blend ? (1.0 - result.a) * color.a : 0.0;
						ro += rd * t;
					}
				}
				return result;
			}
			ENDCG
		}
	}
}