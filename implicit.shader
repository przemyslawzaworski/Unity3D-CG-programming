// Reference: http://iquilezles.org/www/articles/distance/distance.htm
// Rendering 2D implicit equations

Shader "Implicit"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 3.0

			float f (float2 p)                                 
			{
				//for circle with radius 0.5 :
				return p.x * p.x + p.y * p.y - 0.5;
				//for line Ax+By+C=0, where A=8.0, B=4.0, C=1.0 :				
				// return 8.0 * p.x + 4.0 * p.y + 1.0; 
			}

			float2 grad (float2 x)
			{
				float2 h = float2( 0.01, 0.0 );
				return float2( f(x+h.xy) - f(x-h.xy), f(x+h.yx) - f(x-h.yx) )/(2.0*h.x);
			}

			float shape (float2 x)
			{
				float v = f(x);
				float2 g = grad(x);
				float de = abs(v)/length(g);
				return 1.0 - smoothstep( 0.01, 0.02, de );
			}
			
			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
           
			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_TARGET
			{
				uv = float2(2.0*uv-1.0);
				return float4(shape(uv), 0.0, 0.0, 1.0);
			}
			ENDCG
		}
	}
}