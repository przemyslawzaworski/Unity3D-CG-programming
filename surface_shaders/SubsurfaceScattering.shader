// Reference: https://wiki.unity3d.com/index.php/Translucent_Shader

Shader "SubSurfaceScattering" 
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.03, 1)) = 0.1
		_MainTex ("Albedo (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_TransMap ("Translucency Map", 2D) = "white" {}
		_Distortion ("Translucency Distortion", Range(0,0.5)) = 0.2
		_Power("Tranlucency Power", Range(0.0,15.0)) = 1.0
		_Scale("Translucency Scale", Range(0.0,10.0)) = 2.0
	}
	SubShader 
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
		CGPROGRAM
		#pragma surface SurfaceShader SubsurfaceScattering

		sampler2D _MainTex;
		sampler2D _TransMap;
		sampler2D _BumpMap;
		float4 _Color;
		float _Shininess, _Distortion, _Power, _Scale;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		struct SurfaceOutputScattering
		{
			float3 Albedo;
			float3 Normal;
			float3 Emission;
			float Specular;
			float Gloss;
			float Alpha;
			float3 Translucency;
		};

		float4 LightingSubsurfaceScattering (SurfaceOutputScattering s, float3 lightDir, float3 viewDir, float atten)
		{
			float attenuation = (atten * 2);
			float3 h = normalize (lightDir + viewDir);
			float nl = max(0.0, dot (s.Normal, lightDir));
			float nh = max (0.0, dot (s.Normal, h));
			float specular = pow (nh, s.Specular * 128.0) * s.Gloss;
			float3 diffuse = (s.Albedo * _LightColor0.rgb * nl) * attenuation;
			float3 transLight = lightDir + s.Normal * _Distortion;
			float transDot = pow(saturate(dot(viewDir, -transLight)),_Power) * _Scale;
			diffuse += s.Albedo * _LightColor0.rgb * attenuation * (transDot + _Color.rgb) * s.Translucency;
			float4 result = 0;
			result.rgb = diffuse + (_LightColor0.rgb * _SpecColor.rgb * specular) * attenuation;
			result.a = s.Alpha + _LightColor0.a * _SpecColor.a * specular * atten;
			return result;
		}

		void SurfaceShader (Input IN, inout SurfaceOutputScattering o)
		{
			half4 albedo = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = albedo.rgb * _Color.rgb;
			o.Gloss = albedo.a;
			o.Alpha = albedo.a * _Color.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Translucency = tex2D(_TransMap, IN.uv_MainTex).rgb;
		}
		ENDCG
	}
}