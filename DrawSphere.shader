// Draws full procedural sphere with per-face lighting
Shader "Draw Sphere"
{
	Subshader
	{	
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0
			
			float4 VSMain (uint id:SV_VertexID, out float3 p:TEXCOORD0) : SV_POSITION
			{
				float f = id;
				float v = f - 6.0 * floor(f/6.0);  
				f = (f - v) / 6.;
				float a = f - 64.0 * floor(f/64.0);  
				f = (f-a) / 64.;
				float b = f-16.; 
				a += (v - 2.0 * floor(v/2.0));
				b += v==2. || v>=4. ? 1.0 : 0.0;
				a = a/64.*6.28318;
				b = b/64.*6.28318;
				p = float3(cos(a)*cos(b), sin(b), sin(a)*cos(b));
				return UnityObjectToClipPos(float4(p, 1.0));
			}

			float4 PSMain (float4 s:SV_POSITION, float3 p:TEXCOORD0) : SV_Target
			{
				float3 dx = ddx_fine( p );
				float3 dy = ddy_fine( p );
				float3 light1 = normalize(float3(5,0,100));
				float3 light2 = normalize(float3(-100,0,-102));
				float3 light3 = normalize(float3(100,0,-100));	
				float3 normal = normalize(cross(dx,dy));
				float3 diffuse1 = max(dot(light1,normal),0.0) * float3(0.9,0.0,0.0);
				float3 diffuse2 = max(dot(light2,normal),0.0) * float3(0.0,0.9,0.0);
				float3 diffuse3 = max(dot(light3,normal),0.0) * float3(0.0,0.0,1.0);
				return float4(diffuse1+diffuse2+diffuse3,1.0);
			}
			ENDCG
		}
		
	}
}