//references:
//http://graphicsrunner.blogspot.com/2010/08/water-using-flow-maps.html
//https://mtnphil.wordpress.com/2012/08/25/water-flow-shader/

Shader "Flow mapping"
{
	Properties
	{
		_MainTex ("Color Map", 2D) = "black" {}
		_FlowMap ("Flow Map", 2D) = "black" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
				
			sampler2D _MainTex, _FlowMap;
			uniform float FlowMapOffset0;
			uniform float FlowMapOffset1;			
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float HalfCycle = 0.075;		
				float2 flowmap = tex2D( _FlowMap, ps.uv ).rg * 2.0f - 1.0f;
				float phase0 =  FlowMapOffset0;
				float phase1 = FlowMapOffset1;
				float3 A = tex2D(_MainTex, ps.uv + flowmap * phase0 );
				float3 B = tex2D(_MainTex, ps.uv + flowmap * phase1 );
				float flowLerp = ( abs( HalfCycle - FlowMapOffset0 ) / HalfCycle );
				float3 offset = lerp( A, B, flowLerp );
				return float4(offset,1.0);
			}

			ENDCG
		}
	}
}