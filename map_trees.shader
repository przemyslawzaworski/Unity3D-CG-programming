Shader "Map Trees"
{
	Properties
	{
		[HideInInspector]
		_tree ("Tree", Vector) = (0.0,0.0,0.0,0.0)
		[HideInInspector]
		_map ("Texture", 2D) = "black" {}
		
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
		
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _map;
			float4 _tree;
			
			float circle(float2 d, float r)
			{
				return 1.0-smoothstep(r-(r*0.01),r+(r*0.01),dot(d,d));
			}
	
			void vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = float2(ps.uv.xy);
				float k = circle(uv-_tree.xy,0.0002);
				float3 color = float3(k,k,k)*float3(0.0,1.0,0.0);
				color+=tex2Dlod(_map,float4(uv,0.0,0.0));
				fragColor = float4(color,1.0);
			}
			ENDCG
		}
	}
}