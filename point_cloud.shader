//Code written by Przemyslaw Zaworski
//https://github.com/przemyslawzaworski

Shader "Point Cloud"
{
	Properties
	{
		colour("Color", Color) = (1.0,0.0,0.0,1.0)
		A("A",Range(100.0,800.0)) = 400.0    
		B("B",Range(100.0,800.0)) = 400.0    
		C("C",Range(100.0,800.0)) = 400.0 
		I("Intensity",Range(1.0,5.0)) = 3.0	
		[Toggle] variant2("Variant 2", Float) = 0
	}
	SubShader
	{
		Pass
		{
			ZTest Always 
			CGPROGRAM         
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0

			struct Point
			{
				float3 position;
			};
			
			float A,B,C,I,variant2;
			float4 colour;
			StructuredBuffer<Point> cloud; 
									
			float hash(float2 n) 
			{ 
				return frac(sin(dot(n,float2(12.9897, 4.1414)))*43758.5453);
			}

			float noise(float2 p)
			{
				float2 k = floor(p);
				float2 u = frac(p);
				u = u*u*(3.0-2.0*u);	
				float a = hash(k+float2(0.0,0.0));
				float b = hash(k+float2(1.0,0.0));
				float c = hash(k+float2(0.0,1.0));
				float d = hash(k+float2(1.0,1.0));
				float t = lerp(lerp(a,b,u.x),lerp(c,d,u.x),u.y);
				return t*t;
			}
			
			struct type
			{
				float4 vertex : SV_POSITION;
				float3 variable : TEXCOORD1;
			};

			type vertex_shader(uint id : SV_VertexID)
			{
				type vs;
				Point T = cloud[id];
				float x = noise(float2(T.position.yz*_Time.g*0.0001))*A;
				float y = noise(float2(T.position.xz*_Time.g*0.0001))*B;
				float z = noise(float2(T.position.xy*_Time.g*0.0001))*C;
				vs.variable = mul(unity_ObjectToWorld,T.position);
				T.position += float3(x,y,z);
				vs.vertex = UnityObjectToClipPos(float4(T.position,1.0));
				return vs;
			}

			float4 pixel_shader(type ps) : SV_TARGET
			{
				float h = pow(length(ps.variable)*0.003,I);
				if (variant2==0) return float4(colour.rgb*h,1.0);
				else return float4(ps.variable,1.0);
			}
			
			ENDCG
		}
	}
}