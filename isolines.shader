Shader "Isolines"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_sample_base ("SAMPLE_BASE", Range (0.001,1.0)) = 0.7
		_sample_detail ("SAMPLE_DETAIL", Range (0.001,0.3)) = 0.165
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			float _sample_base,_sample_detail;
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			void vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = ps.uv.xy;
				float3 delta = float3(_MainTex_TexelSize.xy,0.0);
				float m = tex2D(_MainTex, float2(uv)).r;
				float a = tex2D(_MainTex, float2(uv + delta.xz)).r;
				float b = tex2D(_MainTex, float2(uv + delta.zy)).r;
				float c = tex2D(_MainTex, float2(uv - delta.xz)).r;
				float d = tex2D(_MainTex, float2(uv - delta.zy)).r;     
				float e = abs(frac(m / _sample_base + 0.5) - 0.5);
				float f = abs(frac(m / _sample_detail + 0.5) - 0.5);
				float2  gradient_base = float2(a-c, b-d) / _sample_base;
				float base = 1.0 - clamp(abs(e) / length(gradient_base), 0.0, 1.0);
				float2  gradient_detail = float2(a-c, b-d) / _sample_detail;
				float detail = 1.0 - clamp(abs(f) / length(gradient_detail), 0.0, 1.0);
				float isoline  = 0.5*base+0.5*detail;     
				fragColor = float4(float3(isoline,isoline,isoline),1.0);
			}
			ENDCG
		}
	}
}