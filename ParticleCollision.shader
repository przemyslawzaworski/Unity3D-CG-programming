Shader "Particle Collision"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex SetVertexShader
			#pragma fragment SetPixelShader
			#pragma target 5.0            

			uniform StructuredBuffer<float4> buffer;
			uniform int resolution;
			uniform int amount;

			void SetVertexShader (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}

			void SetPixelShader (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 color:SV_TARGET)
			{
				float2 texel = float2(round(uv.x*resolution),round(uv.y*resolution));
				color = 0..xxxx;   
				for (int i=0; i<amount; i++) 
				{ 
					float4 k = buffer[resolution+i];      
					float s = distance(texel, (buffer[i]*resolution).xy);
					float a = 1.0 - saturate(s - k.w * resolution + 0.5);  
					color = lerp(color, float4(k.rgb, 1.0), a);
				} 
			} 
 
			ENDCG
		}
	}
}