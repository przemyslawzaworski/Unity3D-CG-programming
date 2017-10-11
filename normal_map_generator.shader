//Need to fix bugs:
//Material goes dark when it is further from camera.
//Specular angle is a bit of incorrect.
//Currently works only with one directional light and skybox.

Shader "Normal Map Generator"
{
	Properties
	{
		_MainTex ("Albedo map", 2D) = "white" {}
		NormalScale ("Normal depth",Range(0.0,20.0)) = 8.0
		SpecularSpread ("Specular Spread",Range(0.0,200.0)) = 100.0
		SpecularPower ("Specular Power",Range(0.0,10.0)) = 1.0
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			float NormalScale;
			float4 _LightColor0;	
			float SpecularSpread;
			float SpecularPower;
			
			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 world_vertex : TEXCOORD1;
			};
	
			float3 NormalGenerator(sampler2D s,float2 uv, float2 texture_size)
			{
				float2 texel = float2(1.0,1.0) / texture_size;
				float3 factor = float3(0.3333,0.3333,0.3333);
				float sample01 = dot(tex2D(s, uv + (float2(-1.0,-1.0)) * texel.xy).rgb, factor);
				float sample02 = dot(tex2D(s, uv + (float2(0.0,-1.0)) * texel.xy).rgb, factor);
				float sample03 = dot(tex2D(s, uv + (float2(1.0,-1.0)) * texel.xy).rgb, factor);	
				float sample04 = dot(tex2D(s, uv + (float2(-1.0,0.0)) * texel.xy).rgb, factor);
				float sample05 = dot(tex2D(s, uv + (float2(0.0,0.0)) * texel.xy).rgb, factor);
				float sample06 = dot(tex2D(s, uv + (float2(1.0,0.0)) * texel.xy).rgb, factor);
				float sample07= dot(tex2D(s, uv + (float2(-1.0,1.0)) * texel.xy).rgb, factor);
				float sample08 = dot(tex2D(s, uv + (float2(0.0,1.0)) * texel.xy).rgb, factor);
				float sample09 = dot(tex2D(s, uv + (float2(1.0,1.0)) * texel.xy).rgb, factor);	
				float2 sobel;
				sobel.x = (sample01-sample03)*0.25+(sample04-sample06)*0.5+(sample07-sample09)*0.25;
				sobel.y = (sample01-sample07)*0.25+(sample02-sample08)*0.5+(sample03-sample09)*0.25;
				return normalize(float3(sobel * NormalScale, 1.0));
			}

			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.screen_vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				vs.world_vertex = mul (_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float2 TextureResolution = float2(_MainTex_TexelSize.z,_MainTex_TexelSize.w);
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.xyz;
				float3 NormalDirection = NormalGenerator(_MainTex,uv,TextureResolution);
				float3 DiffuseColor = tex2D(_MainTex,uv).xyz*(max(dot(LightDirection,NormalDirection),0.0)*LightColor+AmbientLight);	
				float3 SpecularBase = float3 (1.0,1.0,1.0);
				float3 ViewDirection = normalize(ps.world_vertex.xyz - _WorldSpaceCameraPos.xyz) ;
				float3 HalfVector = normalize(LightDirection-ViewDirection);
				float3 SpecularColor = pow(saturate( dot( NormalDirection,HalfVector)),SpecularSpread)*SpecularPower*SpecularBase;
				return float4(DiffuseColor+SpecularColor,1.0);		
			}
			ENDCG
		}
	}
}