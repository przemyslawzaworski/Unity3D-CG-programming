Shader "Blur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_radius ("Blur radius", Range (0.01,2.0)) = 0.5
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			float _radius;
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			void vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			float4 surface (sampler2D input, float2 uv)
			{
				return tex2D(input,uv);   
			}

			float3 blur(float2 uv,float radius)
			{
				float2x2 m = float2x2(-0.736717,0.6762,-0.6762,-0.736717);
				float3 total = float3(0.0,0.0,0.0);
				float2 s = _MainTex_TexelSize.zw;
				float2 texel = float2(0.002*s.x/s.y,0.002);
				float2 angle = float2(0.0,radius);
				radius = 1.0;
				for (int j=0;j<80;j++)
				{  
					radius += 1.0/radius;
					angle = mul(angle,m);
					float3 color = surface(_MainTex,uv+texel*(radius-1.0)*angle).rgb;
					total += color;
				}
				return total/80.0;
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = ps.uv.xy;  
				fragColor = float4(blur(uv,_radius),1.0);
			}
			ENDCG
		}
	}
}