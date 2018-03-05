Shader "FBM generator"
{
	Properties
	{
		_a ("Value1", Range(-10, 10)) = 2.2
		_b ("Value2", Range(-10, 10)) = -2.6
		_c ("Value3", Range(-10, 10)) = -4.3
		_d ("Value4", Range(-10, 10)) = -3.9
		_e ("Value5", Range(-10, 10)) = 1.2
		_f ("Value6", Range(-10, 10)) = -1.8
		_g ("Value7", Range(-10, 10)) = 0.1
		_h ("Value8", Range(-10, 10)) = 3.2
		_color1 ("Color 1", Color) = (0,0,0,1)
		_color2 ("Color 2", Color) = (1,0,0,1)
		_color3 ("Color 3", Color) = (0,0,0,1)
		_color4 ("Color 4", Color) = (1,0,1,1)
		_octaves ("Octaves", Int) = 4
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			float _a,_b,_c,_d,_e,_f,_g,_h;
			float4 _color1,_color2,_color3,_color4;
			int _octaves;
			
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float hash (float2 n)
			{
				return frac(sin(dot(n,float2(123.456789,987.654321)))*54321.9876 );
			}

			float noise(float2 p)
			{
				float2 i = floor(p);
				float2 u = smoothstep(0.0,1.0,frac(p));
				float a = hash(i+float2(0,0));
				float b = hash(i+float2(1,0));
				float c = hash(i+float2(0,1));
				float d = hash(i+float2(1,1));
				float r = lerp(lerp(a,b,u.x),lerp(c,d,u.x),u.y);
				return r*r;
			}

			float fbm( float2 p ,float2x2 m)
			{
				float f = 0.0;
				float d = 0.5;
				float e = 3.0;
				for (int i=0;i<_octaves;++i)
				{
					f += d*noise(p); p = p*e; p = mul(p,m);
					d*=0.5; e*=0.95;
				}
				return f;
			}
			
			void vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 color:SV_Target0) 
			{
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				float2x2 m1 = float2x2(_a,_b,_c,_d);
				float2x2 m2 = float2x2(_e,_f,_g,_h);
				float3 t1 = lerp(_color1,_color2,fbm(uv,m1));
				float3 t2 = lerp(_color3,_color4,fbm(uv,m2));
				color =  float4(max(t1,t2),1.0);
			}
			ENDCG
		}
	}
}