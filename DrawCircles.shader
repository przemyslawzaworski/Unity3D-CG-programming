Shader "Draw Circles"
{
	Subshader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float BufferX[2048]; 
			float BufferY[2048];

			float mod(float x, float y)
			{
				return x - y * floor(x/y);
			}

			float3 hash(float p)
			{
				float3 p3 = frac(p.xxx * float3(.1239, .1237, .2367));
				p3 += dot(p3, p3.yzx+63.33);
				return frac((p3.xxy+p3.yzz)*p3.zyx);
			}

			float4 VSMain (uint id:SV_VertexID, out float2 uv:TEXCOORD0, inout uint instance:SV_INSTANCEID) : SV_POSITION
			{
				float3 center = float3(BufferX[instance], 0.0, BufferY[instance]);
				float u = mod(float(id),2.0);
				float v = sign(mod(126.0,mod(float(id),6.0)+6.0));
				uv = float2(u,v);
				return UnityObjectToClipPos(float4(float3(sign(u)-0.5, 0.0, sign(v)-0.5) + center,1.0));
			}

			float4 PSMain (float4 vertex:SV_POSITION, float2 uv:TEXCOORD0, uint instance:SV_INSTANCEID) : SV_Target
			{
				float2 S = uv*2.0-1.0;
				if (dot(S.xy, S.xy) > 1.0) discard;
				return float4(hash(float(instance)), 1.0);
			}
			ENDCG
		}
	}
}