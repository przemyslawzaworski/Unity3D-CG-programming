//Debug binormals (called also bitangents)

Shader "Binormals"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};
	
			float3 cross(float3 a, float3 b)
			{
				return a.yzx*b.zxy-a.zxy*b.yzx;
			}
	
			structure vertex_shader (float4 vertex:POSITION,float3 normal:NORMAL,float4 tangent:TANGENT)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				float3 binormal = cross(normal,tangent.xyz)*tangent.w;
				vs.color = float4(binormal*0.5+0.5,1.0);
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				return ps.color;
			}

			ENDCG

		}
	}
}