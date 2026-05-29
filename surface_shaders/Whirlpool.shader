// Add material with shader to built-in quad
Shader "Whirlpool"
{
	Properties
	{
		_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		_Displacement("Displacement", Range(0.0, 1.0)) = 0.3	
		_Offset("Offset", Range(0.0, 1.0)) = 0.3
		_Speed("Speed", Range(0.0, 3.0)) = 1.0		
		_Emission("Emission", Range(0.0, 1.0)) = 0.75
	}
	Subshader
	{
		Cull Off
		Tags { "RenderType" = "Opaque" }
		CGPROGRAM
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow vertex:VSMain tessellate:TSMain nolightmap
		#pragma target 5.0

		struct appdata 
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float4 color : COLOR;
		};

		struct Input
		{
			float4 color : COLOR;
		};

		float _Metallic, _Smoothness, _Displacement, _Offset, _Speed, _Emission;

		float SmoothMaximum(float a, float b, float k)
		{
			float h = exp(-k * -a) + exp(-k * -b);
			return -((-a * exp(-k * -a) - b * exp(-k * -b)) / h);
		}

		float SpiralPhase(float2 worldPos)
		{
			float radius = length(worldPos);
			float theta = atan2(worldPos.y, worldPos.x);
			float coords = log(radius + 1e-4) * 1.618 + theta;
			return sin(_Time.y * _Speed * 4.0 + coords * 6.0);
		}

		float WhirlpoolSDF(float3 worldPos, float3 center)
		{
			float2 localPos = worldPos.xz - center.xz;
			float2 offset = 0.2 * float2(cos(_Time.y * _Speed * 2.45), sin(_Time.y * _Speed * 2.45));
			float distortion = 0.03 * SpiralPhase(localPos) + 0.02 * SpiralPhase(localPos + offset * 1.2);
			return length(localPos) - exp(worldPos.y + center.y + distortion);
		}

		float Plane(float3 worldPos, float3 normal, float offset)
		{
			return dot(worldPos, normal) - offset;
		}

		float SignedDistanceField(float3 worldPos)
		{
			float whirlpool = WhirlpoolSDF(worldPos, float3(0.0, _Offset, 0.0));
			float plane = Plane(worldPos, float3(0, 1, 0), 0);
			return SmoothMaximum(-whirlpool, plane, 3.0);
		}

		void VSMain (inout appdata v)
		{	
			float2 uv = float2(2.0 * v.texcoord.xy - 1.0);
			float sdf = SignedDistanceField(float3(uv.x, 0.0, uv.y));
			v.vertex.xyz -= v.normal * sdf * _Displacement;
			v.color = float4(v.texcoord.xy, sdf, 0.0);
		}

		float4 TSMain()
		{
			return 64.0;
		}

		void SurfaceShader (Input IN, inout SurfaceOutputStandard o) 
		{
			o.Albedo = float4((float3) (1.0 - IN.color.z * _Emission), 1.0); 
			o.Normal = float3(0.0,0.0,1.0); 
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			clip(0.5 - length(IN.color.xy - 0.5));
		}
		ENDCG
	}
}