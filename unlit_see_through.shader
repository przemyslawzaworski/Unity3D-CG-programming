//Code has written by Przemyslaw Zaworski, 07.01.2018

Shader "Unlit See Through"
{
	Properties
	{
		surface("Color Map", 2D) = "white" {}
		mask("Mask", 2D) = "white" {}
		[KeywordEnum(Desaturation,Grain,NoName)] filters("Filters", Float) = 0
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

			sampler2D surface,mask;
					
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{			
				float2 mask_uv = ps.vertex.xy / _ScreenParams.xy;
				float4 color = tex2D(mask,mask_uv);
				if (color.x>0.1) 
					discard;
				return tex2D(surface,ps.uv.xy);
			}
			ENDCG
		}
		
		GrabPass { "image" }
		
		Pass 
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D mask, image;
			float filters;
			
			float4 vertex_shader (float4 vertex:position) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 desaturation (float4 x)
			{
				float c = dot(x.rgb, float3(0.2126, 0.7152, 0.0722));
				return float4(c,c,c,1.0);
			}
			
			float4 grain (float4 color, float2 uv)
			{    
				float strength = 16.0;  
				float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (_Time.g * 10.0);
				float t = fmod((fmod(x, 17.0) + 1.0) * (fmod(x, 117.0) + 1.0), 0.01)-0.005;
				float4 grain = float4(t,t,t,1) * strength;
				return color + grain;  
			}
			
			float4 noname (float4 c)
			{    
				return float4(c.r*c.r,sqrt(c.g),1.0-c.b,1.0);  
			}
			
			float4 pixel_shader (float4 vertex:SV_POSITION) : SV_TARGET
			{ 
				float2 mask_uv = vertex.xy / _ScreenParams.xy;
				float4 color = tex2D(mask,mask_uv);
				if (color.x>0.1)
				{
					if (filters==0)
						return desaturation(tex2D(image,mask_uv));  
					else if (filters==1)
						return grain(tex2D(image,mask_uv),mask_uv);
					else 
						return noname(tex2D(image,mask_uv)); 
				}
				else 
					return tex2D(image,mask_uv);
			}

			ENDCG
		}
	}
}