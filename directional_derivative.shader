//Lighting is computed without normal vectors, for faster rendering. 
//Reference: http://iquilezles.org/www/articles/derivative/derivative.htm

Shader "Directional derivative"
{
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			float sphere (float3 p, float3 c, float r)
			{
				return length(p-c)-r;
			}
			
			float map (float3 p)
			{
				return sphere(p,float3(0,0,0),1.0);
			}
			
			float4 lighting (float3 p, float e)
			{
				float4 a = float4 (0.1,0.1,0.1,1.0);       //ambient light color
				float4 b = float4(1.0,1.0,0.0,1.0);       //directional light color
				float3 l = normalize(float3(6,15,-7));   //directional light direction
				float c = (map(p+l*e)-map(p))/e;        //directional derivative equation
				return saturate(c)*b+a;                //return diffuse color
			}
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001) return lighting(ro,0.001);
					ro+=t*rd;
				}
				return 0;
			}
					
			type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (type ps) : COLOR
			{
				float2 resolution = float2(1024,1024); 
				float2 fragCoord = ps.uv*resolution;
				float2 uv = (2.0*fragCoord-resolution)/resolution.y;
				float3 worldPosition = float3(0,0,-10);
				float3 viewDirection = normalize(float3(uv,2.0));			
				return raymarch(worldPosition,viewDirection);
			}
			ENDCG
		}
	}
}