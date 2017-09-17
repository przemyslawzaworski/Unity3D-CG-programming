Shader "Depth"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			sampler2D _CameraDepthTexture;
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float4 screen : TEXCOORD1;
			};

			float4 ComputeScreenPos (float4 p) 
			{
				float4 o = p * 0.5;
				o.xy = float2(o.x, o.y*_ProjectionParams.x) + o.w;     
				o.zw = p.zw;
				return o;
			}
			
			custom_type vertex_shader (float4 vertex:POSITION)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.screen = ComputeScreenPos(vs.vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps) : SV_TARGET
			{
				float d = 1.0/(_ZBufferParams.x*(tex2D(_CameraDepthTexture,ps.screen.xy).r)+_ZBufferParams.y);   
				return float4(d,d,d,1);			
			}
			ENDCG
		}
	}
}