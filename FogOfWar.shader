Shader "Hidden/FogOfWar"
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
			float4 Center;
			float Radius;
			sampler2D _MainTex;	
			
			float circle(float2 p, float2 c, float r)
			{
				return step(length(p-c)-r,0.0);
			}	
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float color:SV_TARGET)
			{
				color = max(circle(uv,Center.xy,Radius), tex2D(_MainTex,uv).r);
			}
			
			ENDCG
		}
		
		Pass
		{ 
			CGPROGRAM
			sampler2D _Buffer, _Map;
			
			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 color:SV_TARGET)
			{
				color = tex2D(_Buffer,uv).r > 0.0 ? tex2D(_Map,uv) : float4(0,0,0,1);
			}
			
			ENDCG
		}		
	}
}