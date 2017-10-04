/*
World Space Vector Displacement Mapping, no lighting, triangle tessellation
*/

Shader "Vector Displacement Mapping" 
{
	Properties 
	{
		_MainTex ("Diffuse Map", 2D) = "white" {}
		_displacement ("Vector Displacement Map", 2D) = "white" {}
		_displacement_scale ("Displacement Scale", Range(0, 2)) = 1
		_tessellation_scale ("Tessellation Scale", Range(0, 100)) = 10
		_offsetX ("OffsetX", Range(-1, 1)) = 0.0
		_offsetY ("OffsetY", Range(-1, 1)) = 0.0
		_offsetZ ("OffsetZ", Range(-1, 1)) = 0.0			
	}
	SubShader
	{
		Pass 
		{       
			CGPROGRAM
			#pragma vertex vertex_shader			
			#pragma hull hull_shader
			#pragma domain domain_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
      
			sampler2D _MainTex; 
			sampler2D _displacement; 
			float _tessellation_scale;
			float _displacement_scale;
			float _offsetX,_offsetY,_offsetZ;
			
			struct VertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
			struct VertexOutput 
			{
				float4 screen_vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 world_vertex : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};
			
			VertexOutput vert (VertexInput v) 
			{
				VertexOutput o;
				o.uv = v.uv;
				o.normalDir = normalize(_World2Object[0].xyz*v.normal.x+_World2Object[1].xyz*v.normal.y+_World2Object[2].xyz*v.normal.z);
				v.vertex.xyz += ((tex2Dlod(_displacement,float4(o.uv,0.0,0.0)).xyz*float3(_offsetX,_offsetY,_offsetZ))*_displacement_scale);
				o.world_vertex= mul(_Object2World, v.vertex);
				o.screen_vertex= mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
            
			struct tessellation 
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			
			struct OutputPatchConstant 
			{
				float edge[3]: SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};
			
			tessellation vertex_shader (VertexInput v) 
			{
				tessellation o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				o.texcoord0 = v.uv;
				return o;
			}
			
			OutputPatchConstant constantsHS (InputPatch<tessellation,3> patch) 
			{
				OutputPatchConstant o;
				float t = _tessellation_scale;
				o.edge[0]=o.edge[1]=o.edge[2]=o.inside=t;
				return o;
			}
			
			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("constantsHS")]
			[outputcontrolpoints(3)]
			
			tessellation hull_shader (InputPatch<tessellation,3> patch, uint id : SV_OutputControlPointID) 
			{
				return patch[id];
			}
			
			[domain("tri")]
			VertexOutput domain_shader (OutputPatchConstant tessFactors,const OutputPatch<tessellation,3> vs, float3 d:SV_DomainLocation) 
			{
				VertexInput v;
				v.vertex = vs[0].vertex*d.x + vs[1].vertex*d.y + vs[2].vertex*d.z;
				v.normal = vs[0].normal*d.x + vs[1].normal*d.y + vs[2].normal*d.z;
				v.uv = vs[0].texcoord0*d.x + vs[1].texcoord0*d.y + vs[2].texcoord0*d.z;
				v.vertex.xyz +=((tex2Dlod(_displacement,float4(v.uv,0.0,0.0)).xyz*float3(_offsetX,_offsetY,_offsetZ))*_displacement_scale);
				VertexOutput o = vert(v);
				return o;
			}

			float4 pixel_shader(VertexOutput ps) : SV_TARGET
			{
				return tex2D(_MainTex,ps.uv);
			}
			ENDCG
		}      
	}
}
