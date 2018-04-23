Shader "Normal Map Diffuse"
{
	Properties
	{
		_MainTex ("Diffuse Map", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}		
	}
	Subshader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct APPDATA 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct SHADERDATA
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 vertex : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float3 tangent : TEXCOORD3;
				float3 binormal : TEXCOORD4;
			};

			float4 _LightColor0, _MainTex_ST, _NormalMap_ST ;
			sampler2D _MainTex, _NormalMap;

			SHADERDATA vertex_shader (APPDATA input)
			{
				SHADERDATA vs;
				vs.position = UnityObjectToClipPos (input.vertex);
				vs.uv = input.uv;
				vs.vertex = mul( unity_ObjectToWorld, input.vertex );
				vs.normal = normalize(mul((float3x3)unity_ObjectToWorld,input.normal));
				vs.tangent = normalize(mul((float3x3)unity_ObjectToWorld,input.tangent.xyz));
				vs.binormal = normalize(cross(vs.normal,vs.tangent)*input.tangent.w);				
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : COLOR
			{
				float4 color = tex2D( _MainTex, ps.uv * _MainTex_ST.xy + _MainTex_ST.zw );
				float4 packednormal = tex2D( _NormalMap, ps.uv * _NormalMap_ST.xy + _NormalMap_ST.zw );	
				float3 normal = float3(2.0*packednormal.ag-1.0,0.0);   //convert from 0..1 range to -1..1 range
				normal.z = sqrt(1.0 - dot(normal, normal));   //reconstruct depth
				float3x3 tbn = float3x3(ps.tangent,ps.binormal,ps.normal);   //generate matrix
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.rgb;
				float3 NormalDirection = normalize(mul(normal,tbn));   //transform from Tangent Space to World Space
				return float4((max(dot(LightDirection, NormalDirection),0.0)*LightColor+AmbientLight)*color.rgb,color.a);	
			}
			ENDCG
		}
	}
}