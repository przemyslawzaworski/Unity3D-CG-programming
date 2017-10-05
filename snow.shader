//source: https://www.shadertoy.com/view/ldsGDn
Shader "Snow"
{
	Properties
	{
		LAYERS("Layers",Int) = 100
		DEPTH("Depth",Range(0.0,1.0)) = 0.2
		WIDTH("Width",Range(0.0,2.0)) = 0.9	
		SPEED("Speed",Range(0.0,2.0)) = 0.9					 
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			int LAYERS ;
			float DEPTH,WIDTH,SPEED ;
			static const float3x3 p = float3x3(13.323122,23.5112,21.71123,21.1212,28.7312,11.9312,21.8112,14.7212,61.3934);
			
			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul (UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float3 acc = float3(0.0,0.0,0.0);
				float dof = 5.*sin(_Time.g*.1);
				for (int i=0;i<LAYERS;i++) 
				{
					float f = float(i);
					float2 q = uv*(1.+f*DEPTH);
					q += float2(q.y*(WIDTH*fmod(f*7.238917,1.)-WIDTH*.5),SPEED*_Time.g/(1.+f*DEPTH*.03));
					float3 n = float3(floor(q),31.189+f);
					float3 m = floor(n)*.00001 + frac(n);
					float3 mp = (31415.9+m)/frac(mul(m,p));
					float3 r = frac(mp);
					float2 s = abs(fmod(q,1.)-0.5+0.9*r.xy-0.45);
					s += 0.01*abs(2.*frac(10.*q.yx)-1.0); 
					float d = .6*max(s.x-s.y,s.x+s.y)+max(s.x,s.y)-.01;
					float edge = .005+.05*min(.5*abs(f-5.-dof),1.);
					float t = smoothstep(edge,-edge,d)*(r.x/(1.+.02*f*DEPTH));
					acc += float3(t,t,t);
				}
				return float4(float3(acc),1.0);		
			}
			ENDCG
		}
	}
}