// Tessellation and Geometry Shader example

Shader "Quadrangulation" 
{
	Properties 
	{	
		_TessellationFactor ("Tessellation Factor", Range(0, 64)) = 16
		_QuadSize ("Quad Size", Float) = 0.05
	}
	SubShader 
	{
		Pass 
		{	
			CGPROGRAM

			#pragma vertex VSMain 
			#pragma hull HSMain
			#pragma domain DSMain
			#pragma geometry GSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float _TessellationFactor, _QuadSize;

			struct CONTROL_POINT
			{
				float4 position : SV_POSITION;
			};
			
			CONTROL_POINT VSMain (float4 vertex:POSITION) 
			{
				CONTROL_POINT vs;
				vs.position = vertex;
				return vs;
			}
 
			void constantsHS (InputPatch<CONTROL_POINT,3> V, out float edge[3]:SV_TessFactor, out float inside:SV_InsideTessFactor) 
			{
				edge[0] = edge[1] = edge[2] = _TessellationFactor;
				inside = _TessellationFactor;  
			}

			[domain("tri")]
			[partitioning("integer")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("constantsHS")]
			[outputcontrolpoints(3)]
			
			CONTROL_POINT HSMain (InputPatch<CONTROL_POINT,3> V, uint ID : SV_OutputControlPointID) 
			{
				return V[ID];
			}

			[domain("tri")]
			CONTROL_POINT DSMain ( float edge[3]:SV_TessFactor, float inside:SV_InsideTessFactor, const OutputPatch<CONTROL_POINT,3> P, float3 K : SV_DomainLocation) 
			{
				CONTROL_POINT ds; 
				ds.position =  float4(P[0].position.xyz*K.x + P[1].position.xyz*K.y + P[2].position.xyz*K.z, 1.0);
				return ds;
			}

			[maxvertexcount(64)] 
			void GSMain( triangle CONTROL_POINT patch[3], inout TriangleStream<CONTROL_POINT> stream )
			{
				CONTROL_POINT GS;
				float3 delta = float3 (_QuadSize, 0.00, 0.00);
				float3 center = float3((patch[0].position.xyz + patch[1].position.xyz + patch[2].position.xyz) / 3);
				GS.position = UnityObjectToClipPos(center + delta.yyy);
				stream.Append(GS);
				GS.position = UnityObjectToClipPos(center + delta.yyx);
				stream.Append(GS);
				GS.position = UnityObjectToClipPos(center + delta.xyy);
				stream.Append(GS);
				GS.position = UnityObjectToClipPos(center + delta.xyy);
				stream.Append(GS);
				GS.position = UnityObjectToClipPos(center + delta.xyx);
				stream.Append(GS);
				GS.position = UnityObjectToClipPos(center + delta.yyx);
				stream.Append(GS);
				stream.RestartStrip();
			}
			
			float4 PSMain (CONTROL_POINT ps) : SV_Target
			{
				return 0; 
			}
			ENDCG
		}
	}

}