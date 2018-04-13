Shader "Tessellation" 
{
	Properties 
	{
		_ColorMap ("Color Map", 2D) = "black" {}
		_TessellationFactor ("Tessellation Factor", Range(0, 64)) = 16
	}
	SubShader 
	{
		Tags {"RenderType"="Opaque"}
		Pass 
		{
			Tags {"LightMode"="ForwardBase"}          
			CGPROGRAM
			#pragma vertex vertex_shader			
			#pragma hull hull_shader
			#pragma domain domain_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			
			float _TessellationFactor;
			float4 _ColorMap_ST;
			sampler2D _ColorMap; 
			
			struct APPDATA 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct VS_CONTROL_POINT_OUTPUT 
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct HS_CONSTANT_DATA_OUTPUT 
			{
				float edge[3]         : SV_TessFactor;
				float inside          : SV_InsideTessFactor;
				float3 vTangent[4]    : TANGENT;
				float2 vUV[4]         : TEXCOORD;
				float3 vTanUCorner[4] : TANUCORNER;
				float3 vTanVCorner[4] : TANVCORNER;
				float4 vCWts          : TANWEIGHTS;
			};
			
			VS_CONTROL_POINT_OUTPUT vertex_shader (APPDATA i) 
			{
				VS_CONTROL_POINT_OUTPUT vs;
				vs.vertex = i.vertex;
				vs.normal = i.normal;
				vs.tangent = i.tangent;
				vs.uv = i.uv;
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
				ds.vertex = UnityObjectToClipPos(P[0].vertex*K.x + P[1].vertex*K.y + P[2].vertex*K.z);
				ds.normal = P[0].normal*K.x + P[1].normal*K.y + P[2].normal*K.z;
				ds.tangent = P[0].tangent*K.x + P[1].tangent*K.y + P[2].tangent*K.z;
				ds.uv = P[0].uv*K.x + P[1].uv*K.y + P[2].uv*K.z;
				return vertex_shader(ds);
			}

			float4 pixel_shader(VS_CONTROL_POINT_OUTPUT ps) : SV_TARGET 
			{
				return tex2D(_ColorMap,ps.uv*_ColorMap_ST.xy+_ColorMap_ST.zw);
			}
			ENDCG
		}
	}
}
