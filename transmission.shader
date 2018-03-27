//Shader controls how much light is passed through object when the light source is behind the surface currently being rendered. 
//This can be useful for materials such as cloth or vegetation.

Shader "Transmission" 
{
	Properties 
	{
		_MainTex ("Diffuse map", 2D) = "white" {}
		_Range ("Range", Range(0, 3)) = 1
	}
	SubShader 
	{
		Cull Off
		Tags {"RenderType"="Opaque"}
		Pass 
		{
			Tags {"LightMode"="ForwardBase"}                      
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			float4 _LightColor0, _MainTex_ST;
			sampler2D _MainTex;
			float _Range;
			
			struct structure 
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
			};
			
			structure vertex_shader (float4 vertex:POSITION,float3 normal:NORMAL,float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos( vertex );
				vs.normal = normalize(mul(unity_ObjectToWorld,normal));				
				vs.uv = uv;
				return vs;
			}
			
			float4 pixel_shader(structure ps) : COLOR 
			{
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT.rgb; 			
				float3 NormalDirection = ps.normal;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.rgb;
				float NdotL = dot( NormalDirection, LightDirection );
				float3 ForwardLight = max(0.0, NdotL);
				float3 BackLight = max(0.0, -NdotL ) * float3(_Range,_Range,_Range);
				float3 DiffuseColor = (ForwardLight+BackLight) * LightColor + AmbientLight;
				float3 DiffuseMap = tex2D(_MainTex,ps.uv*_MainTex_ST.xy+_MainTex_ST.zw).rgb;
				return float4(DiffuseColor*DiffuseMap,1.0);
			}
			ENDCG
		}
	}
}
