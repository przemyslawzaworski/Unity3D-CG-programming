//source: https://www.shadertoy.com/view/4tlBz8
//translated from ShaderToy to Unity by Przemyslaw Zaworski
//usage: shader has access to UV coordinates, so can be applied to base game object
Shader "Tiny Clouds"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv: TEXCOORD0;
			};

			float hash(float2 n) 
			{ 
				return frac(sin(dot(n,float2(12.9898,4.1414)))*43758.5453);
			}

			float noise (float3 position)
			{    
				float2 uv = (position.yz+ceil(position.x))*0.005;   
				float2 p = frac(uv) * 256.0;    
				float2 uv_frac = p - floor(p);    
				float2 uv_floor = floor(p) * 0.00390625;
				float2 uv_ceil = ceil(p) * 0.00390625;    
				float a = hash(float2(uv_floor.x, uv_floor.y));
				float b = hash(float2(uv_floor.x, uv_ceil.y ));
				float c = hash(float2(uv_ceil.x , uv_floor.y));
				float d = hash(float2(uv_ceil.x , uv_ceil.y ));    
				float e = lerp(a, b, uv_frac.y);
				float f = lerp(c, d, uv_frac.y);   
				return  lerp(e,f,uv_frac.x);
			}
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv=uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float2 iResolution = float2(1024,1024);
				float2 fragCoord = ps.uv.xy*iResolution;
				float3 rd = float3(0.8, fragCoord/iResolution.y-0.8);
				float3 sky = float3(0.6, 0.7, 0.8);
				float3 c = sky - rd.z;
				for (int i = 0; i < 200; ++i)
				{
					float3 ro = 0.05 * float(200 - i) * rd;
					ro.xy+=_Time.g;
					float s = 0.5;
					float t = ro.z + 1.25;      
					for (int k=0; k<5; ++k)
					{
						ro *= 2.0;
						s *= 2.0;
						t -= noise(ro) / s;
					}
					if (t<0.0) c = c+(c-1.0-t*sky.zyx)*t*0.4;
				}   
				return float4(c,1.0);
			}

			ENDCG
		}
	}
}