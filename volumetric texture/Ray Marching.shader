Shader "Hidden/Ray Marching/Ray Marching" 
{
	Subshader 
	{
		ZTest Always Cull Off ZWrite Off		
		Pass 
		{
		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			sampler3D _VolumeTex;
			sampler2D _FrontTex;
			sampler2D _BackTex;	
			float4 _ClipDims;	
			float4 _ClipPlane;
			
			custom_type vertex_shader( float4 vertex:POSITION, float2 uv:TEXCOORD0 ) 
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos(vertex);		
				vs.uv = uv;			
				return vs;
			}
			

			#define STEP_CNT 128
			#define STEP_SIZE 1 / 128.0
			
			float4 raymarch(float2 uv) 
			{
				float3 front = tex2D(_FrontTex, uv).xyz;		
				float3 back = tex2D(_BackTex, uv).xyz;				
				float3 rd = back - front;
				float3 ro = front;
				float4 dst = 0;						
				for(int k = 0; k < STEP_CNT; k++)
				{
					float4 src = tex3D(_VolumeTex, ro);
					float border = step(1 - _ClipDims.x, ro.x);
					border *= step(ro.y, _ClipDims.y);
					border *= step(ro.z, _ClipDims.z);
					border *= step(0, dot(_ClipPlane, float4(ro - 0.5, 1)) + _ClipPlane.w);					
					src.a *= saturate(border);  
					src.rgb *= src.a; 
					dst = (1.0 - dst.a) * src + dst;
					ro += rd * STEP_SIZE;
				}
				return 2.0*dst;
			}
			
			float4 pixel_shader(custom_type ps) : SV_TARGET 
			{ 
				float2 uv = ps.uv.xy;
				return raymarch(uv); 
			}	

			ENDCG
		}
	}
}

	
