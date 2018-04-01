//Set deferred rendering path and DirectX 11. Assign point_cloud_with_shadow.cs to GameObject and
//material with shader. Light source can be directional, point light, etc. 
//Special thanks for forum.unity.com user "BrkTbn" (help and support)

Shader "Point Cloud with Shadow"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,0)
	}
	SubShader
	{
		Pass 
		{
			Tags {"LightMode"="Deferred"}     
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma exclude_renderers nomrt
			#pragma multi_compile ___ UNITY_HDR_ON
			#pragma target 5.0
		
			half3 _Color;
			StructuredBuffer<float3> cloud;	

			struct structurePS
			{
				half4 albedo : SV_Target0;
				half4 specular : SV_Target1;
				half4 normal : SV_Target2;
				half4 emission : SV_Target3;
			};
			
			float4 vertex_shader (uint id : SV_VertexID) : SV_POSITION
			{
				float3 position = cloud[id];
				position.xz+=2.0*length(position.xz)*cos(_Time.g);
				return UnityObjectToClipPos(float4(position,1.0));			
			}

			structurePS pixel_shader (void)
			{
				structurePS ps;
				ps.albedo = half4( 0,0,0,0 );
				ps.specular = half4( 0,0,0,0 );
				ps.normal = half4( 0,0,0,0 );
				ps.emission = half4(_Color,1);
				return ps;
			}
			ENDCG
		}
	}
}