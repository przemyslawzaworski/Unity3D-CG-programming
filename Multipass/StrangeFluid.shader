// Original reference: https://www.shadertoy.com/view/XdcGW2

Shader "StrangeFluid"
{
	SubShader
	{

//-------------------------------------------------------------------------------------------
	
		CGINCLUDE
		#pragma vertex SetVertexShader
		#pragma fragment SetPixelShader
		
		void SetVertexShader (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}
		
		ENDCG

//-------------------------------------------------------------------------------------------
		
		Pass
		{ 
			CGPROGRAM
			sampler2D _BufferA;	
			int iFrame;
			float4 iMouse;
			float4 iResolution;
			
			float4 get_pixel(float x_offset, float y_offset, float2 uv)
			{
				return tex2D(_BufferA, (uv) + (float2(x_offset, y_offset) / iResolution.xy));
			}
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float val = get_pixel(0.0, 0.0, uv).r;
				val += frac(sin(dot(uv * iResolution.xy, float2(12.9898,78.233))) * 43758.5453)* val * 0.15;
				val = get_pixel(
					sin(get_pixel(val, 0.0, uv).r  - get_pixel(-val, 0.0, uv) + 3.1415).r  * val * 0.4, 
					cos(get_pixel(0.0, -val, uv).r - get_pixel(0.0 , val, uv) - 3.1415/2.0).r * val * 0.4, uv
				).r;
				val *= 1.0001;
			 
				if(iFrame < 2)
					val = frac(sin(dot(uv * iResolution.xy, float2(12.9898,78.233))) * 43758.5453)*length(iResolution.xy)/100.0 + 
						smoothstep(length(iResolution.xy)/2.0, 0.5, length(iResolution.xy * 0.5 - uv * iResolution.xy))*25.0;
				
				if (iMouse.z > 0.0) 
					val += smoothstep(length(iResolution.xy)/10.0, 0.5, length(iMouse.xy - uv * iResolution.xy));
					
				fragColor = float4(val, 0, 0, 0);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
	
		Pass
		{ 
			CGPROGRAM
			sampler2D _BufferA;
			float4 _BufferA_TexelSize;
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float val = tex2D(_BufferA, uv).r;       
				float4 color = pow(float4(cos(val), tan(val), sin(val), 1.0) * 0.5 + 0.5, float4(0.5, 0.5, 0.5, 0.5));      
				float3 e = float3(_BufferA_TexelSize.xy, 0.0);
				float p10 = tex2D(_BufferA, uv - e.zy).x;
				float p01 = tex2D(_BufferA, uv - e.xz).x;
				float p21 = tex2D(_BufferA, uv + e.xz).x;
				float p12 = tex2D(_BufferA, uv + e.zy).x;
				float3 grad = normalize(float3(p21 - p01, p12 - p10, 1.0));
				float3 light = normalize(float3(.2,-.25,.7));
				float diffuse = dot(grad,light);
				float spec = pow(max(0.0,-reflect(light,grad).z),32.0); 
				fragColor = (color * diffuse) + spec;
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}