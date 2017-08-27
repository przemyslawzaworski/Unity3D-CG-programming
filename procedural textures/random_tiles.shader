Shader "Random Tiles"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#pragma exclude_renderers gles
			
			float4 vertex_shader (float4 vertex : POSITION) : POSITION
			{
				return UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (float2 f:VPOS) : COLOR
			{
				float2 u = f/_ScreenParams.xy*10.;    
				u.x += _Time.g*lerp(-2.4,.8,fmod(ceil(u.y),2.)); 
				return frac(sin(mul(ceil(u)/8.,float2x4(90,29.5,49.2,0,0,13.3,31.9,1)))*4e5);	
			}
			ENDCG
		}
	}
}