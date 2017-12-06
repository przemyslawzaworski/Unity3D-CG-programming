//reference: https://www.shadertoy.com/view/MdSfW1
Shader "Twister"
{
	Properties
	{
		pattern ("Texture", 2D) = "black" {}
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D pattern;
			
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

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 P = ps.uv*4.0-2.0;
				float4 c = float4(0.36,0.64,0.58,1.0);    
				float T = _Time.g, a = P.y*sin(T) + T*2. + sin(P.y + T);       
				for (int n = 0; n < 4; n++) 
				{
					float A = cos(a), B = sin(a);
					if (P.x > A && P.x < -B) 
					{
						float2 uv = float2((P.x - A)/(-B - A), P.y*.5);            
						c = tex2Dlod(pattern, float4(uv,0,0))*-(B + A)*(uv.x< 0.02 ? 1.5 : 1.0);
					}               
					a += 1.5707;
				}  
				return c;			
			}
			ENDCG
		}
	}
}