Shader "Hidden/VoronoiCones"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			struct Seed
			{
				float2 Location;
				float3 Color;
			};
	
			StructuredBuffer<float3> _Cone;
			StructuredBuffer<Seed> _Seeds;
			float4x4 _ModelViewProjection;
			int _Animation;
			float _SeedSize, _ConeHeight;

			float4 VSMain (uint id : SV_VertexID, uint instance : SV_InstanceID, out float3 color : COLOR, out float4 worldPos : WORLDPOS) : SV_POSITION
			{
				worldPos = float4(_Cone[id] + float3(_Seeds[instance].Location, 0.0), 1.0);
				worldPos.xy += _Animation * float2(sin(_Time.g + instance), cos(_Time.g - instance)) * 0.5;
				color = _Seeds[instance].Color;
				return mul(_ModelViewProjection, worldPos);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 color : COLOR, float4 worldPos : WORLDPOS) : SV_Target
			{
				return worldPos.z <= (-_ConeHeight + _SeedSize) ? float4(0, 0, 0, 1) : float4(color, 1);
			}
			ENDCG
		}
	}
}