Shader "ProceduralGeometry"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader 
	{
		Pass 
		{
			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 5.0  
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4  _LightColor0;

			struct Point
			{
				float3 vertex;
				float3 normal;
				float4 tangent;
				float2 uv;
			};      

			StructuredBuffer<Point> points;
 
			struct custom_type
			{
				float4 position : SV_POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (uint id : SV_VertexID, uint inst : SV_InstanceID)
			{
				custom_type vs;
				float4 vertex_position =  float4(points[id].vertex,1.0f);
				float4 vertex_normal = float4(points[id].normal, 1.0f);
				vertex_position.x+=sin(5.0*_Time.g);
				vs.position = mul (UNITY_MATRIX_VP, vertex_position);
				vs.uv = TRANSFORM_TEX(points[id].uv, _MainTex);
				float3 NormalDirection = normalize(vertex_normal.xyz);
				float4 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float4 LightDirection = normalize(_WorldSpaceLightPos0);
				vs.color = saturate(dot(LightDirection, NormalDirection))*_LightColor0+AmbientLight;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_Target
			{
				return tex2D(_MainTex, ps.uv)*ps.color;
			}

			ENDCG
		}
	}
}