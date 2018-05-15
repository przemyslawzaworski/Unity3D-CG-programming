Shader "MRT" 
{
	SubShader 
	{
		Pass 
		{
			ZTest Always Cull Off ZWrite Off      	
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma exclude_renderers nomrt
			#pragma target 3.0

			struct structureVS 
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct structurePS
			{
				float4 target00 : SV_Target0;
				float4 target01 : SV_Target1;
				float4 target02 : SV_Target2;
				float4 target03 : SV_Target3;
			};

			structureVS vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				structureVS vs;
				vs.vertex = UnityObjectToClipPos( vertex );			
				vs.uv = uv;
				return vs;
			}

			structurePS pixel_shader (structureVS vs)
			{
				structurePS ps;
				ps.target00 = float4(1,0,0,1);
				ps.target01 = float4(0,1,0,1);
				ps.target02 = float4(0,0,1,1);
				ps.target03 = float4(1,1,1,1);
				return ps;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}