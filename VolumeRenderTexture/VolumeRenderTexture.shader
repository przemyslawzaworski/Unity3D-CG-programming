Shader "Volume Render Texture"
{
	SubShader 
	{
		Cull Back
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			sampler3D _Volume;

			void VSMain(inout float4 vertex:POSITION, out float3 world:WORLD)
			{
				world = mul(unity_ObjectToWorld, vertex).xyz;
				vertex = UnityObjectToClipPos(vertex);
			}

			float4 PSMain(float4 vertex:POSITION, float3 world:WORLD) : SV_Target
			{
				float3 ro = mul(unity_WorldToObject, float4(world, 1)).xyz;
				float3 rd = normalize(mul((float3x3) unity_WorldToObject, normalize(world - _WorldSpaceCameraPos))); 
				float3 tbot = (1.0 / rd) * (-0.5 - ro);
				float3 ttop = (1.0 / rd) * (0.5 - ro);
				float3 tmin = min(ttop, tbot);
				float3 tmax = max(ttop, tbot);
				float2 a = max(tmin.xx, tmin.yz);
				float tnear = max(0.0,max(a.x, a.y));
				float2 b = min(tmax.xx, tmax.yz);
				float tfar = min(b.x, b.y);
				float3 d = normalize((ro + rd * tfar) - ro) * (abs(tfar - tnear) / 128.0);
				float4 t = float4(0, 0, 0, 0);
				[unroll]
				for (int i = 0; i < 128; i++)
				{
					float v = tex3D(_Volume, ro+0.5).r;
					float4 s = float4(v, v, v, v);
					s.a *= 0.5;
					s.rgb *= s.a;
					t = (1.0 - t.a) * s + t;
					ro += d;
					if (t.a > 0.99) break;
				}
				return saturate(t);
			}

			ENDCG
		}
	}
}