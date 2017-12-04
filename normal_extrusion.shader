Shader "Normal extrusion"
{
	Properties
	{
		_MainTex ("Extrusion map", 2D) = "white" {}
		_color("Color intensity",Range(0.0,1.0)) = 0.5
		_displacement("Displacement",Range(0.0,8.0)) = 2.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			float _displacement;
			float _color;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0; 
				float3 normal : TEXCOORD1;
				float height : TEXCOORD2;
			};
	
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0,float3 normal:NORMAL)
			{
				structure vs;
				float offset=tex2Dlod (_MainTex,float4(uv.xy,0,0)).r*_displacement;
				vertex.xyz+=normal*offset;
				vs.height=offset;
				vs.vertex=UnityObjectToClipPos(vertex);
				vs.uv=uv;
				vs.normal=normal;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float h = ps.height*_color; 
				return float4(h,h,h,1.0);			
			}
			ENDCG
		}
	}
}