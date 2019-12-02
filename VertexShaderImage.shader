Shader "Vertex Shader Image"
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

			float2 PolarToCartesian (float2 p)
			{	
				return p.x * float2(cos(p.y),sin(p.y));
			}

			float2 CartesianToPolar (float2 p)
			{
				return float2(length(p), atan2(p.y, p.x));
			}

			float3 Pattern (float2 uv)
			{
				uv = CartesianToPolar (abs(uv));
				uv = (12.0*uv);   
				uv = PolarToCartesian(uv); 
				return float3(4.0/abs(uv),uv.x/uv.y);
			}

			float4 VSMain (uint id:SV_VertexID, out float3 color:TEXCOORD0) : SV_POSITION
			{
				float q = floor(float(id) / 6.0);
				float px = fmod(float(id), 2.0);
				float py = (float(id)-6.0 * floor(float(id)/6.0)) + 6.0;
				py = sign(126.0-py*floor(126.0/py));
				float3 center = float3(fmod(q,1024.0), 0.0, floor(q/1024.0));
				float error = 0.0000001;
				float2 uv = float2(center.x / 1024.0, center.z / 1024.0) + error;
				uv = float2(2.0*uv-1.0);
				color = Pattern(uv);
				float scale = 0.1;
				return UnityObjectToClipPos(float4(float3(sign(px)-0.5, 0.0, sign(py)-0.5) * scale + center * scale, 1.0));
			}
 
			float4 PSMain (float4 vertex:SV_POSITION, float3 color:TEXCOORD0) : SV_Target
			{
				return float4(color, 1.0);
			}
			
			ENDCG
		}
	}
}