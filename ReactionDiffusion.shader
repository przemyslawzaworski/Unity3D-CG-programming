//reference: https://www.shadertoy.com/view/XsG3z1

Shader "ReactionDiffusion"
{
	SubShader
	{
	
		CGINCLUDE
		#pragma vertex SetVertexShader
		#pragma fragment SetPixelShader
		
		void SetVertexShader (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}
		
		ENDCG
		
		Pass
		{ 
			CGPROGRAM			
			sampler2D _MainTex;	
			float4 _MainTex_TexelSize;
			int iFrame;
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{ 
				float3 e = float3(1, 0, -1);
				float2 px = _MainTex_TexelSize.xy;
				float res = 0.0; 
				res += tex2D(_MainTex,uv + e.xx*px ).x + tex2D(_MainTex,uv + e.xz*px ).x + tex2D(_MainTex,uv + e.zx*px ).x +tex2D(_MainTex,uv + e.zz*px ).x;
				res += (tex2D(_MainTex,uv + e.xy*px ).x + tex2D(_MainTex,uv + e.yx*px ).x + tex2D(_MainTex,uv + e.yz*px ).x + tex2D(_MainTex,uv + e.zy*px ).x)*2.;
				res += tex2D(_MainTex,uv + e.yy*px ).x*4.;
				float avgReactDiff =  res/16.; 
				float3 noise = frac(float3(2097152, 262144, 32768)*sin(dot(uv + float2(53, 43)*_Time.g, float2(41, 289))))*.6 + .2; 
				float2 pwr = px*1.5; 
				float2 lap = float2(tex2D(_MainTex,uv + e.xy*pwr).y - tex2D(_MainTex,uv - e.xy*pwr).y, tex2D(_MainTex,uv + e.yx*pwr).y - tex2D(_MainTex,uv - e.yx*pwr).y);
				uv = uv + lap*px*3.0 ; 
				float newReactDiff = tex2D(_MainTex,uv).x + (noise.z - 0.5)*0.0025 - 0.002; 
				newReactDiff += dot(tex2D(_MainTex,uv + (noise.xy-0.5)*px).xy, float2(1, -1))*0.205;
				if (iFrame<1) 
				{
					fragColor = float4(noise, 1.); 
				}
				else if (iFrame<100) 
				{
					if(uv.x>0.35 && uv.x<0.65 && uv.y>0.35 && uv.y<0.65) fragColor = float4(clamp(float2(newReactDiff, avgReactDiff/.99), 0., 1.),0,0);
					else fragColor = float4(0,0,0,0);
				}
				else
				{     
					 fragColor = float4(clamp(float2(newReactDiff, avgReactDiff/.99), 0., 1.),0,0); 
				} 
			}
			
			ENDCG
		}
		
		Pass
		{ 
			CGPROGRAM
			sampler2D _Buffer;
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 color:SV_TARGET)
			{
				float t = 1.4 - tex2D(_Buffer,uv).y;
				color = t.xxxx;
			}
			
			ENDCG
		}		
	}
}