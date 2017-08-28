// Source: https://www.shadertoy.com/view/lsSyDw
Shader "Wood"
{
	Properties
	{
		_offsetX("Offset X", Float) = 0.0
		_offsetY("Offset Y", Float) = 0.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			float _offsetX, _offsetY;

			float random (float2 uv) 
			{
				return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
			}

			float noise (float2 uv) 
			{
				float2 i = floor(uv);
				float2 f = frac(uv);
				float a = random(i);
				float b = random(i + float2(1, 0));
				float c = random(i + float2(0, 1));
				float d = random(i + float2(1, 1));
				float2 u = f * f * (3.0 - 2.0 * f);
				return lerp(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
			}

			float fbm (float2 uv) 
			{
				float value = 0.0;
				float amplitud = 0.5;
				float frequency = 0.0;
				for (int i = 0; i < 6; i++) 
				{
					value += amplitud * noise(uv);
					uv *= 2.0;
					amplitud *= 0.5;
				}
				return value;
			}
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = ps.uv.xy + float2(_offsetX,_offsetY);  
				float3 value = float3(0.860, 0.806, 0.574);  
				float planks = abs(sin(uv.x*10.0));
				value *= planks; 
				float3 colorA = float3(0,0,0);
				value = lerp(value,colorA,float3(fbm(uv.xx*10.),fbm(uv.xx*10.),fbm(uv.xx*10.)));    	
				value = lerp(value,float3(0.390,0.265,0.192),float3(fbm(uv.xx*22.),fbm(uv.xx*22.),fbm(uv.xx*22.)));
				value = lerp(value,float3(0.930,0.493,0.502),random(uv.xx)*.1);
				value -= (noise(uv*float2(500., 14.)-noise(uv*float2(1000., 64.)))*0.1);   
				return float4(value,1.0);			
			}
			
			ENDCG
		}
	}
}