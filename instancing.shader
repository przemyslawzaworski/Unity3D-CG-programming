﻿Shader "Instancing" 
{
	CGINCLUDE
	#pragma vertex vertex_shader
	#pragma fragment pixel_shader 
	#pragma target 5.0
	sampler2D GrassTexture;
	StructuredBuffer<float4> GeometryBuffer;
	float CutOff;
	ENDCG
	
	SubShader 
	{
		Tags { "IgnoreProjector"="True" "RenderType"="Grass" "DisableBatching"="True"}
		Pass 
		{
			Tags{ "LightMode" = "ForwardBase" }
			Cull Off				
			CGPROGRAM		
			#pragma multi_compile_fwdbase
			#include "AutoLight.cginc"

			struct APPDATA
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				uint instanceID : SV_InstanceID;
			};
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 _ShadowCoord : TEXCOORD1;
			};
			
			float4 ComputeScreenPos (float4 p) 
			{
				float4 o = p * 0.5;
				return float4(o.x + o.w, o.y*_ProjectionParams.x + o.w, p.zw);     
			}
			
			SHADERDATA vertex_shader (APPDATA data)
			{
				SHADERDATA vs;
				float4 buffer = GeometryBuffer[data.instanceID];				
				vs.vertex = mul(UNITY_MATRIX_VP, buffer + data.vertex);
				vs.uv = data.uv;
				vs._ShadowCoord = ComputeScreenPos(vs.vertex);
				return vs;
			}
			
			float4 pixel_shader (SHADERDATA ps) : SV_Target
			{
				float attenuation = SHADOW_ATTENUATION(ps);
				float4 color = tex2D(GrassTexture, ps.uv);				
				clip (color.a-CutOff);
				return color * attenuation ;
			}
			ENDCG
		}
		
		Pass
		{
			Tags{ "LightMode" = "ShadowCaster" }	
			Cull Off   				
			CGPROGRAM
														
			void vertex_shader (inout float4 vertex:POSITION,inout float2 uv:TEXCOORD0,uint i:SV_InstanceID)
			{				
				vertex = mul(UNITY_MATRIX_VP,GeometryBuffer[i]+vertex);
			}
			
			float4 pixel_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_Target
			{
				float4 color = tex2D(GrassTexture,uv);				
				clip (color.a-CutOff);
				return 0;
			}
			ENDCG
		}				
	}	
}