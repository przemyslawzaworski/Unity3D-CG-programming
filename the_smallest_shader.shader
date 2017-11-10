//Probably the smallest Unity shaderlab program, which is visible in engine (you can even return zero in vertex shader, but object won't be visible).
//Author: Przemyslaw Zaworski 10.11.2017 Unity version: 5.3.5
Shader "A"
{
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex V
			#pragma fragment P
			half4 V(half4 X:POSITION):POSITION{return mul(UNITY_MATRIX_MVP,X);}
			half4 P():COLOR{return 0;}
			ENDCG
		}
	}
}