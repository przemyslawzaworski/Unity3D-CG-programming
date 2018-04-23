//Author: Przemyslaw Zaworski
//Shader supports maximum four splat textures (Splat and Normal maps) with triangle tessellation.
//Works seamlessly with built-in Terrain Component. Lambert light model (directional) with shadow casting and receiving.

Shader "Terrain Shader Tessellation Diffuse" 
{
	Properties 
	{
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}		
		_TessellationFactor ("Tessellation Factor", Range(0, 64)) = 16
	}
	SubShader 
	{
		Tags {"RenderType" = "Opaque"}
		Pass 
		{	
			Tags {"LightMode" = "ForwardBase" "SplatCount" = "4" "Queue" = "Geometry-100"}
			CGPROGRAM

			#pragma vertex vertex_shader 
			#pragma hull hull_shader
			#pragma domain domain_shader
			#pragma fragment pixel_shader
			#pragma target 5.0

			#pragma multi_compile_fwdbase
			#include "AutoLight.cginc"

			sampler2D _Control;
			float4 _Control_ST;
			sampler2D _Splat0;
			sampler2D _Splat1;
			sampler2D _Splat2;
			sampler2D _Splat3;
			float4 _Splat0_ST;
			float4 _Splat1_ST;
			float4 _Splat2_ST;
			float4 _Splat3_ST;
			float _TessellationFactor;
			float4 _LightColor0;
			
			sampler2D _Normal0, _Normal1, _Normal2, _Normal3;
			
			struct APPDATA
			{
				float2 tc_Control: COLOR;
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv_Splat0 : TEXCOORD0;
				float2 uv_Splat1 : TEXCOORD1;
				float2 uv_Splat2 : TEXCOORD2;
				float2 uv_Splat3 : TEXCOORD3; 
			};
		
			struct VS_CONTROL_POINT_OUTPUT 
			{
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv_Splat0 : TEXCOORD0; 
				float2 uv_Splat1 : TEXCOORD1;
				float2 uv_Splat2 : TEXCOORD2;
				float2 uv_Splat3 : TEXCOORD3;
				float2 tc_Control : COLOR;
				float4 _ShadowCoord : TEXCOORD4;			
			};

			struct HS_CONSTANT_DATA_OUTPUT 
			{
				float edge[3] : SV_TessFactor;
				float inside  : SV_InsideTessFactor;
			};

			float4 ComputeScreenPos (float4 p) 
			{
				float4 o = p * 0.5;
				o.xy = float2(o.x, o.y*_ProjectionParams.x) + o.w;     
				o.zw = p.zw;
				return o;
			}
			
			VS_CONTROL_POINT_OUTPUT vertex_shader (APPDATA i) 
			{
				VS_CONTROL_POINT_OUTPUT vs;
				vs.position = i.vertex;
				vs.normal = i.normal;
				vs.uv_Splat0 = i.uv_Splat0;
				vs.uv_Splat1 = i.uv_Splat1;
				vs.uv_Splat2 = i.uv_Splat2;
				vs.uv_Splat3 = i.uv_Splat3;
				vs.tc_Control	= i.tc_Control;
				vs._ShadowCoord = ComputeScreenPos(vs.position);
				return vs;
			}
 
			HS_CONSTANT_DATA_OUTPUT constantsHS (InputPatch<VS_CONTROL_POINT_OUTPUT,3> V) 
			{
				HS_CONSTANT_DATA_OUTPUT output = (HS_CONSTANT_DATA_OUTPUT)0;
				output.edge[0] = output.edge[1] = output.edge[2]  = _TessellationFactor;
				output.inside = _TessellationFactor;  
				return output;
			}

			[domain("tri")]
			[partitioning("integer")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("constantsHS")]
			[outputcontrolpoints(3)]

			VS_CONTROL_POINT_OUTPUT hull_shader (InputPatch<VS_CONTROL_POINT_OUTPUT,3> V, uint ID : SV_OutputControlPointID) 
			{
				return V[ID];
			}

			[domain("tri")]
			VS_CONTROL_POINT_OUTPUT domain_shader (HS_CONSTANT_DATA_OUTPUT input, const OutputPatch<VS_CONTROL_POINT_OUTPUT,3> P, float3 K : SV_DomainLocation) 
			{
				APPDATA ds;
				ds.vertex = UnityObjectToClipPos(P[0].position*K.x + P[1].position*K.y + P[2].position*K.z);
				ds.normal = (P[0].normal*K.x + P[1].normal*K.y + P[2].normal*K.z);
				ds.uv_Splat0 = (P[0].uv_Splat0*K.x + P[1].uv_Splat0*K.y + P[2].uv_Splat0*K.z)*_Splat0_ST.xy+_Splat0_ST.zw;
				ds.uv_Splat1 = (P[0].uv_Splat1*K.x + P[1].uv_Splat1*K.y + P[2].uv_Splat1*K.z)*_Splat1_ST.xy+_Splat1_ST.zw;
				ds.uv_Splat2 = (P[0].uv_Splat2*K.x + P[1].uv_Splat2*K.y + P[2].uv_Splat2*K.z)*_Splat2_ST.xy+_Splat2_ST.zw;
				ds.uv_Splat3 = (P[0].uv_Splat3*K.x + P[1].uv_Splat3*K.y + P[2].uv_Splat3*K.z)*_Splat3_ST.xy+_Splat3_ST.zw;
				ds.tc_Control = (P[0].uv_Splat0*K.x + P[1].uv_Splat0*K.y + P[2].uv_Splat0*K.z)*_Control_ST.xy+_Control_ST.zw;
				return vertex_shader(ds);
			}

			float4 pixel_shader (VS_CONTROL_POINT_OUTPUT ps) : SV_Target
			{
				float3 normal = normalize(mul((float3x3)unity_ObjectToWorld,ps.normal));
				float4 tangent = float4 (cross(ps.normal, float3(0,0,1)),-1);
				tangent.xyz = normalize(mul((float3x3)unity_ObjectToWorld,tangent.xyz));
				float3 binormal = normalize(cross(normal,tangent)*tangent.w);
				float4 splat_control = tex2D (_Control, ps.tc_Control);
				float weight = dot(splat_control, half4(1,1,1,1));
				clip(weight == 0.0f ? -1 : 1);
				splat_control /= (weight + 1e-3f);
				float3 color  = splat_control.r * tex2D (_Splat0, ps.uv_Splat0).rgb;
				color += splat_control.g * tex2D (_Splat1, ps.uv_Splat1).rgb;
				color += splat_control.b * tex2D (_Splat2, ps.uv_Splat2).rgb;
				color += splat_control.a * tex2D (_Splat3, ps.uv_Splat3).rgb;
				float4 nrm = splat_control.r * tex2D(_Normal0, ps.uv_Splat0);
				nrm += splat_control.g * tex2D(_Normal1, ps.uv_Splat1);
				nrm += splat_control.b * tex2D(_Normal2, ps.uv_Splat2);
				nrm += splat_control.a * tex2D(_Normal3, ps.uv_Splat3);
				nrm.rgb = float3(2.0*nrm.ag-1.0, 0.0);
				nrm.b = sqrt(1.0 - dot(nrm.rgb,nrm.rgb));
				float3x3 tbn = float3x3(tangent.xyz,binormal,normal);			
				float attenuation = SHADOW_ATTENUATION(ps);
				float3 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;
				float3 LightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 LightColor = _LightColor0.xyz*attenuation;
				float3 NormalDirection = normalize(mul(nrm.rgb, tbn));
				float3 diffuse = max(dot(LightDirection, NormalDirection),0.0) * LightColor + AmbientLight;
				return float4(color*weight*diffuse,1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}