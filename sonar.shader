Shader "Sonar"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float circle(float2 d, float r)
			{
				return smoothstep(r-(r*0.2),r+(r*0.2),dot(d,d));
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float a = circle(uv-float2(0.5,0.5),0.04*sin(fmod(_Time.g*0.4,1.0)));
				float b = 1.0-(circle(uv-float2(0.5,0.5),0.05*sin(fmod(_Time.g*0.4,1.0))));	
				float3 c = float3(0.0,0.0,min(a,b));
				return float4(c,1.0)*(1.0-(sin((fmod(_Time.g*0.4,1.0)))));
			}
			ENDCG
		}
	}
}