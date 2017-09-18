Shader "Heptagon"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0; 
			};

			float heptagon(float2 p, float r)
			{
				float k = atan2(p.y,p.x)+1.5708;
				return length(p)*cos(0.8976*floor(0.5+k*1.1141)-k)-r;
			}
			
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				float c = smoothstep(0.001,0.0,heptagon(uv,0.5));
				return float4(c,0,0,1);	
			}
			ENDCG
		}
	}
}