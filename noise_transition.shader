//Play to see the effect.
Shader "Noise Transition"
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

			float hash(float2 n) 
			{ 
				return frac(sin(dot(n, float2(12.9898,4.1414)))*43758.5453);
			}

			type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (type ps) : COLOR
			{
				float2 uv = ps.uv.xy+float2(floor(_Time.g),1.0);
				float2 s = ceil(uv*10.0)/10.0;
				float t = hash(s);
				float a = -sign(fmod(_Time.g,2.0)-t);
				float b = sign(fmod(_Time.g-1.0,2.0)-t);
				float4 c = {a,a,a,1.0};
				float4 d = {b,b,b,1.0};
				if (fmod(_Time.g,2.0)<1.0) return  c;
				else return d;
			}
			ENDCG
		}
	}
}