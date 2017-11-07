Shader "Diagonal transition"
{
	Properties
	{
		[HideInInspector]
		_MainTex ("Texture", 2D) = "black" {}
		_Background ("Background", 2D) = "black" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			sampler2D _MainTex,_Background;

			float remap (float x, float a, float b, float c, float d)  
			{
				return (x-a)/(b-a)*(d-c) + c; 
			}
			
			float4 vertex_shader (float4 vertex:POSITION):SV_POSITION
			{
				return mul(UNITY_MATRIX_MVP,vertex);
			}

			float4 pixel_shader (float4 vertex:SV_POSITION):COLOR
			{
				vector <float,2> uv = vertex.xy/_ScreenParams.xy;
				vector <float,2> uv2 = vertex.xy/_ScreenParams.xy;
				uv2.y=1.0-uv2.y;
				vector <float,4> a = tex2D(_MainTex,uv);
				vector <float,4> b = tex2D(_Background,uv2);
				float time = fmod(_Time.g,12.0);
				if (fmod(floor((uv.y+(uv.x)*remap(cos(time),-1.0,1.0,0.0,2.0))*10.0),2.0)==0.0)
				{
					if (time<=6.0) return (uv.x<time*0.3) ? a:b; 
					else return (uv.x<(time-6.0)*0.3) ? b:a; 
				}
				else
				{
					if (time<=6.0) return (1.0-uv.x<time*0.3) ? a:b; 
					else return (1.0-uv.x<(time-6.0)*0.3) ? b:a; 
				}					
			}
			ENDCG
		}
	}
}