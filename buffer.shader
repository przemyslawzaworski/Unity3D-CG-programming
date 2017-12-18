//original source: https://www.shadertoy.com/view/4sc3DB
//translated from GLSL to CG by Przemyslaw Zaworski
//Shader has been used to demonstrate self-accumulated buffer in Unity.
//Usage: apply script to gameobject ( quad ), then material with shader to script and to the quad mesh renderer.
//Visit for more info: https://forum.unity.com/threads/converting-a-shadertoy-multipass-shader-to-unity-hlsl.418238/

Shader "Buffer"
{
	Properties
	{
		MainTex ("Texture", 2D) = "black" {}
	}
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
				
			sampler2D MainTex;
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : SV_TARGET
			{
				float2 iResolution = float2(1024,1024);
				float2 uv = ps.uv.xy;
				if (length(float2(sin(_Time.g)*.75,cos(_Time.g*1.1294)*.75)-(uv*2.-1.))<.06) return float4(1.,0.,1.,1.);    
				float4 c = tex2Dlod(MainTex, float4(uv,0,0))*5.;   
				float2 odr = 1./iResolution.xy;   
				float4 cLeft = tex2Dlod(MainTex, float4(uv-float2(odr.x,0.),0,0));
				float4 cRight = tex2Dlod(MainTex, float4(uv+float2(odr.x,0.),0,0));
				float4 cUp = tex2Dlod(MainTex, float4(uv-float2(0.,odr.y),0,0));
				float4 cDown = tex2Dlod(MainTex, float4(uv+float2(0.,odr.y),0,0));  
				c += cLeft.wyzx*(abs(cos(_Time.g+uv.x*32.234+cRight.w*32.234))+1.);
				c += cRight.zxyw*(abs(cos(uv.x*32.234+cLeft.z*32.34+_Time.g*1.36))+1.);
				c += cUp*(abs(cos(_Time.g*2.12+uv.y*32.1432+cDown.y*32.24))+1.);
				c += cDown.wzyx*(abs(cos(uv.y*32.345+cUp.x*32.234))+1.);       
				return max(c/11.6-.0001, 0.);
			}
			ENDCG
		}
	}
}