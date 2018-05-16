Shader "Collision Mesh - Plane"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0

			uniform float4 A;
			uniform float4 B;
			uniform float4 C;
			
			struct Plane 
			{
				float3 n; 
				float d; 
			};

			Plane ComputePlane(float3 a, float3 b, float3 c)
			{
				Plane p;
				p.n = normalize(cross(b - a, c - a));
				p.d = dot(p.n, a);
				return p;
			}

			float DistPointPlane(float3 q, Plane p)
			{
				return dot(q, p.n) - p.d; 
			}
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float dist : TEXCOORD1;
			};
			
			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				Plane plane = ComputePlane(A.xyz,B.xyz,C.xyz);   
				vs.dist = DistPointPlane(mul(unity_ObjectToWorld,vertex),plane);
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{	
				if (abs(ps.dist)<0.001)
					return float4(0,0,1,1);
				else 
					return float4(0,0,0,1);
			}

			ENDCG

		}
	}
}