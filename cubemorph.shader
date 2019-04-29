// Morph input shape (for example Sphere) to cube, with normal reconstruction and diffuse lighting

Shader "Cubemorph"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			
			float4 _LightColor0;
			
			float3 morph (float3 base)
			{
				float3 offset = base;
				offset *= 2.0 / length(offset.xyz);
				offset = 0.5*clamp( offset.xyz, -1.0, 1.0 );
				return lerp(base,offset,sin(_Time.g)*0.5+0.5);
			}
			
			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0, inout float3 normal:NORMAL, float4 tangent:TANGENT)
			{
				float3 position = morph( vertex );
				float3 bitangent = cross( normal, tangent.xyz );
				float3 nt = ( morph( vertex + tangent.xyz * 0.01 ) - position ); 
				float3 nb = ( morph( vertex + bitangent * 0.01 ) - position );
				normal = cross( nt, nb );
				vertex = UnityObjectToClipPos(float4(position,vertex.w));
			}
			
			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, float3 normal:NORMAL) : SV_TARGET
			{
				float3 LightDirection = normalize( _WorldSpaceLightPos0 );
				float3 NormalDirection = normalize(mul((float3x3)unity_ObjectToWorld,normal));
				float3 diffuse = max(dot(LightDirection, NormalDirection),0.0) * _LightColor0;
				return float4(diffuse, 1);
			}
			ENDCG
		}
	}
}