//based on https://github.com/Flafla2/Generic-Raymarch-Unity
Shader "Raymarching Full Integration"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#include "UnityCG.cginc"
			
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _MainTex;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float4x4 _FrustumCornersES;
			uniform float4 _CameraWS;
			float4 _LightColor0; 
			
			struct custom_type
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};
			
			float cuboid (float3 p,float3 c,float3 s)
			{
				float3 d = abs(p-c)-s;
				return float(max(max(d.x,d.y),d.z));
			}
			
			float map(float3 p) 
			{
				return cuboid(p,float3(0.0,0.0,0.0),float3(1.0,1.0,1.0));
			}

			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.01,0.00,0.00);
				float3 y = float3 (0.00,0.01,0.00);
				float3 z = float3 (0.00,0.00,0.01);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}

			float3 lighting (float3 p)
			{
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.xyz;
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight);
			}
			 
			float4 raymarch(float3 ro, float3 rd, float s) 
			{
				float t = 0; 
				for (int i = 0; i < 128; i++) 
				{
					if (t >= s ) return float4(0,0,0,0);
					float3 p = ro + rd * t; 
					float d = map(p);		
					if (d < 0.001) return float4(lighting(p),1.0);
					t += d;
				}
				return float4(0,0,0,0);
			}

			custom_type vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				custom_type vs;				
				half index = vertex.z;
				vertex.z = 0.1;				
				vs.pos = UnityObjectToClipPos(vertex);
				vs.uv = uv.xy;
				vs.ray = _FrustumCornersES[(int)index].xyz;
				vs.ray /= abs(vs.ray.z);
				vs.ray = mul(_CameraInvViewMatrix, vs.ray);
				return vs;
			}
			
			float4 pixel_shader (custom_type ps) : SV_Target
			{
				float3 ro = _CameraWS;			
				float3 rd = normalize(ps.ray);
				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture,ps.uv).r)*length(ps.ray);
				float4 color = tex2D(_MainTex,ps.uv);
				float4 volume = raymarch(ro, rd, depth);
				return lerp(color,volume,volume.w);
			}
			ENDCG
		}
	}
}
