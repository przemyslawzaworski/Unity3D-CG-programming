Shader "Drunk"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			sampler2D _MainTex;

			float4 vertex_shader (float4 vertex:POSITION):SV_POSITION
			{
				return mul(UNITY_MATRIX_MVP,vertex);
			}

			float4 pixel_shader (float4 vertex:SV_POSITION):COLOR
			{
				vector <float,2> uv = vertex.xy/_ScreenParams.xy;
				uv.x+=cos(uv.y*2.0+_Time.g)*0.05;
				uv.y+=sin(uv.x*2.0+_Time.g)*0.05;
				float offset = sin(_Time.g *0.5) * 0.01;    
				float4 a = tex2D(_MainTex,uv);    
				float4 b = tex2D(_MainTex,uv-float2(sin(offset),0.0));    
				float4 c = tex2D(_MainTex,uv+float2(sin(offset),0.0));    
				float4 d = tex2D(_MainTex,uv-float2(0.0,sin(offset)));    
				float4 e = tex2D(_MainTex,uv+float2(0.0,sin(offset)));        
				return (a+b+c+d+e)/5.0;
			}
			ENDCG
		}
	}
}