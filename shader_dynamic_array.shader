Shader "Shader Dynamic Array"
{
	Properties
	{
		_MainTexture ("Main Texture", 2D) = "black" {}
		_SubTexture ("Sub Texture", 2D) = "black" {}		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
				
			sampler2D _SubTexture,_MainTexture;
			uniform int count;
			uniform sampler1D array;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float4 quad (float2 center,float size,sampler2D input,float2 uv)
			{
				float a = center.x-size*0.5;
				float b = center.x+size*0.5;
				float c = center.y-size*0.5;
				float d = center.y+size*0.5;    
				float2 bl = step(float2(a,c),uv);       
				float2 tr = step(float2(1.0-b,1.0-d),1.0-uv);
				float n = bl.x * bl.y * tr.x * tr.y;
				float2 st = (uv-float2(a,c))/(float2(b,d)-float2(a,c));
				float4 output = lerp(float4(0,0,0,1),tex2D(input,st).rgba,tex2D(input,st).a);
				return float4(float3(n,n,n),1.0)*output;
			}

			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float total;
				for (int i=0;i<count;i++)
				{
						float p = 1.0/float(count-1); 
						float2 value = tex1D(array,i*p).xy;
						total = max(total,quad(value,0.05,_SubTexture,ps.uv)); 
				}				
				return total+tex2D(_MainTexture,ps.uv);
			}

			ENDCG
		}
				
	}
}