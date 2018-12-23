Shader "Procedural Skybox"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader
			
			void SetVertexShader (inout float4 Vertex:POSITION, out float3 Point:TEXCOORD0)
			{
				Point = mul(unity_ObjectToWorld, Vertex);   // World Space coordinate
				Vertex = UnityObjectToClipPos (Vertex);   // Screen Space coordinate
			}

			void SetPixelShader (float4 Vertex:POSITION, float3 Point:TEXCOORD0, out float4 Color:SV_TARGET)
			{
				float3 Direction = normalize(Point - _WorldSpaceCameraPos);   //Direction vector
				Color = (Direction.y>0.0) ? Direction.yyyy : 0;   //Pixel color
			}

			ENDCG
		}
	}
}