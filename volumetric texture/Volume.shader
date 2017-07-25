Shader "Ray Marching/Volume"
{
	SubShader
	{
		Tags {"RenderType" = "Volume"}

		ZWrite Off

		Pass
		{
			ColorMask 0
		}
	}

	FallBack Off
}
