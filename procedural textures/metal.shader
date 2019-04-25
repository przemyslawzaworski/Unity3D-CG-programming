Shader "Metal"
{
	Properties
	{
		_scale ("Scale", Int) = 2
		_pattern ("Pattern", Range(1.0,10.0)) = 6.0
		_height ("Height", Range(1.0,10.0)) = 10.0
		_epsilon ("Epsilon", Range(0.01,0.1)) = 0.1
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			float _pattern, _height, _epsilon;
			int _scale;

			float smin(float a, float b, float r)
			{
				float h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
				return lerp (b, a, h) - r * h * (1. - h);
			}

			float mod(float x, float y)
			{
				return x - y * floor(x/y);
			}

			float map(float3 pos)
			{
				float cd = 2./(_pattern + 1.05);
				float dd = 0.13 + 0.025 * _pattern;
				pos.xz = float2(pos.x*0.7071 - pos.z*0.7071, pos.x*0.7071 + pos.z*0.7071);
				pos.xz = (mod(floor(pos.x) + floor(pos.z), 2.)==0.) ? pos.zx : pos.xz; 
				pos.x = frac(pos.x*_pattern) - 0.5;
				pos.z = frac(pos.z) - 0.5;    
				float a = -(distance(float3(cd, 0., 0.), pos*float3(1., _height, 1.)) - cd - dd);
				float b = -(distance(float3(-cd, 0., 0.), pos*float3(1., _height, 1.)) - cd - dd);
				float k = -smin(a, b, 0.06);   
				return - smin(-smin(pos.y, k, 0.01), -(pos.y - _epsilon), 0.12);
			}

			float4 lighting (float3 p)
			{
				float2 q = float2(0, 0.001);
				float3 n = normalize(float3(map(p+q.yxx)-map(p-q.yxx),map(p+q.xyx)-map(p-q.xyx),map(p+q.xxy)-map(p-q.xxy)));
				float3 l = normalize(_WorldSpaceLightPos0.xyz);
				return float4(clamp(dot(n, l), 0., 1.).xxx, 1.); 
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<32; i++)
				{
					float t = map(ro);
					if ( t<0.001 ) return lighting (ro);
					ro+=t*rd;
				}
				return 0;
			}
			
			void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
			{
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0) : SV_TARGET
			{
				uv = float2(2.0*uv-1.0);
				float3 ro = float3(0., 5., 0.);
				float3 rd = normalize(mul(float3x3(1,0,0,0,0,-1,0,1,0), float3(uv * _scale, 2.0)));
				return raymarch(ro, rd); 
			}
			ENDCG
		}
	}
}