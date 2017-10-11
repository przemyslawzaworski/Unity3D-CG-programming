//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). 
//Add fly script to Main Camera. Play. 
//Or just bind material with shader to any gameobject to create volumetric effect :)
Shader "3D Fractal Generator"
{
	Properties
	{
		I("Iteration",Int) = 50
		R("Raymarching",Int) = 50
		A("A",Range(0.01,2.0)) = 1.25
		B("B",Range(0.01,2.0)) = 1.07   
		C("C",Range(0.01,2.0)) = 1.29
		D("D",Range(0.00,2.0)) = 0.95    
		E("E",Range(0.00,2.0)) = 0.91   
		F("F",Range(0.00,2.0)) = 0.67
		G("G",Range(0.00,100.0)) = 50
		N("N",Range(0.00,0.5)) = 0.1	
		T("T",Range(0.00,100.0)) = 3.0	
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			int I,R;
			float A,B,C,D,E,F,G,N,T;

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
 
			float3 map (float3 p)
			{
				for (int i = 0; i < I; ++i)
				{
					p = float3(A,B,C)*abs(p/dot(p,p)-float3(D,E,F));    
				}	
				return p/G;
			}
		
			float4 raymarch(float3 ro, float3 rd)
			{
				float3 c = float3(0,0,0);
				for(int i=0; i<R; ++i)
				{
					T+=N;
					c+=map(ro+T*rd);
				}
				return float4(c,1.0);
			}	

			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.world_vertex = mul(_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex-_WorldSpaceCameraPos.xyz);
				return raymarch (worldPosition,viewDirection);
			} 
			
			ENDCG
		}
	}
}