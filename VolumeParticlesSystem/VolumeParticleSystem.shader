Shader "Volume Particle System"
{
	Subshader
	{	
		Pass
		{
			Tags {"LightMode"="Deferred"} 
			Cull Off
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma exclude_renderers nomrt
			#pragma multi_compile ___ UNITY_HDR_ON
			#pragma target 5.0

			int _Amount;
			float _Speed;
			float _Spread;
			float _ParticleOpacity;
			float _Height;
			float _ParticleScale;
			float _Lifetime;
			float _DiffuseShading;
			float4 _StartColor;
			float4 _MiddleColor;
			float4 _EndColor;
			float4 _EmitterPosition;
			int _EmitterCycles;
			float _Timer;
			float _RotationX, _RotationY, _RotationZ, _GroundLevel;
			
			#include "UnityPBSLighting.cginc"
					
			float3x3 rotationX( float x) 
			{
				return float3x3(1.0,0.0,0.0,0.0,cos(x),sin(x),0.0,-sin(x),cos(x));
			}	
			
			float3x3 rotationY( float y) 
			{
				return float3x3(cos(y),0.0,-sin(y),0.0,1.0,0.0,sin(y),0.0,cos(y));
			}

			float3x3 rotationZ( float z) 
			{
				return float3x3(cos(z),sin(z),0.0,-sin(z),cos(z),0.0,0.0,0.0,1.0);
			}			
			
			float3 hash3( float3 x )
			{
				x = float3( dot(x,float3(127.1,311.7, 74.7)), dot(x,float3(269.5,183.3,246.1)), dot(x,float3(113.5,271.9,124.6)));
				return frac(sin(x)*43758.5453123);
			}

			float3 voronoi( in float3 x )
			{
				float3 p = floor( x );
				float3 f = frac( x );
				float id = 0.0;
				float2 res = float2( 100.0, 100.0 );
				for( int k=-1; k<=1; k++ )
				for( int j=-1; j<=1; j++ )
				for( int i=-1; i<=1; i++ )
				{
					float3 b = float3( float(i), float(j), float(k) );
					float3 r = float3( b ) - f + hash3( p + b );
					float d = dot( r, r );
					if( d < res.x )
					{
						id = dot( p+b, float3(1.0,57.0,113.0 ) );
						res = float2( d, res.x );
					}
					else if( d < res.y )
					{
						res.y = d;
					}
				}
				return float3( sqrt( res ), abs(id) );
			}
						
			float3 hash(uint p)
			{
				p = p;
				p = 1103515245U*((p >> 1U)^(p));
				uint h32 = 1103515245U*((p)^(p>>3U));
				uint n = h32^(h32 >> 16);
				uint3 rz = uint3(n, n*16807U, n*48271U);
				return float3((rz >> 1) & uint3(0x7fffffffU,0x7fffffffU,0x7fffffffU))/float(0x7fffffff);
			}
			
			void GenerateCube (inout uint id, inout float3 normal, inout float3 position, inout float instance)
			{
				float PI = 3.14159265;
				float q = floor((id-36.0*floor(id/36.0))/6.0); 
				float s = q-3.0*floor(q/3.0); 
				float inv = -2.0*step(2.5,q)+1.0;
				float f = id-6.0*floor(id/6.0);
				float t = f-floor(f/3.0); 
				float a = (t-6.0*floor(t/6.0))*PI*0.5+PI*0.25;
				float3 p = float3(cos(a),0.707106781,sin(a))*inv;
				float x = (s-2.0*floor(s/2.0))*PI*0.5; 
				float4x4 mat = float4x4(1,0,0,0,0,cos(x),sin(x),0,0,-sin(x),cos(x),0,0,0,0,1);
				float z = step(2.0,s)*PI*0.5;
				mat = mul(mat,float4x4(cos(z),-sin(z),0,0,sin(z),cos(z),0,0,0,0,1,0,0,0,0,1));
				position = (mul(float4(p,1.0),mat)).xyz;
				normal = (mul(float4(float3(0,1,0)*inv,0),mat)).xyz;
				instance = floor(id/36.0);
			}
			
			float3 Parabola(float3 start, float3 end, float height, float t)
			{
				float p = t * 2 - 1;
				float3 d = end - start;
				float3 s = start + t * d;
				s.y += ( -p * p + 1 ) * height;
				return s;
			}
	
			float remap (float x, float a, float b, float c, float d)  
			{
				return (x-a)/(b-a)*(d-c) + c; 
			}
	
			float4 VSMain (uint id:SV_VertexID, out float3 normal:TEXCOORD0, out float3 position:TEXCOORD1, out float instance:TEXCOORD2, out float3 color:TEXCOORD3, out float3 finalcolor:TEXCOORD4) : SV_POSITION
			{
				GenerateCube (id, normal, position, instance);
				position = mul(rotationY(_Time.g*1.7-instance), mul(rotationX(_Time.g*3.0+instance),position));
				color = position;
				int x = uint(instance) % _Amount;
				int y = (uint(instance) / _Amount) % _Amount;
				int z = uint(instance) / (_Amount*_Amount);
				float3 uv = (float3(x,y,z) / float(_Amount)) * 2.0 - 1.0 ;
				float factor = instance / (_Amount * _Amount * _Amount);
				float range = remap(_Timer* _Speed  ,0.0,_Lifetime + factor,0.0,1.0);
				float h = remap(fmod(_Timer* _Speed ,_Lifetime + factor) ,0.0,_Lifetime+ factor,0.0,1.0);
				finalcolor = lerp(lerp(_StartColor, _MiddleColor, h/0.5), lerp(_MiddleColor, _EndColor, (h - 0.5)/(1.0 - 0.5)), step(0.5, h));
				float range3 = remap(_Spread*hash(uint(instance)),0.0,_Spread,-_Spread,_Spread);
				position += Parabola(uv, uv*range3.xxx, _Height, fmod(_Timer* _Speed + 2.0*(_Lifetime + factor),_Lifetime + factor));
				if (range >= float(_EmitterCycles)) return 0;
				position *= float3(_ParticleScale,_ParticleScale,_ParticleScale);
				position += _EmitterPosition.xyz;				
				position = mul(rotationX(radians(_RotationX)),position);
				position = mul(rotationY(radians(_RotationY)),position);
				position = mul(rotationZ(radians(_RotationZ)),position);
				position.y = max (position.y, _GroundLevel);
				return UnityObjectToClipPos(float4(position,1.0));
			}
			
			struct structurePS
			{
				half4 albedo : SV_Target0;
				half4 specular : SV_Target1;
				half4 normal : SV_Target2;
				half4 emission : SV_Target3;
			};
			
			structurePS PSMain (float4 vertex:SV_POSITION, float3 normal:TEXCOORD0, float3 position:TEXCOORD1, float instance:TEXCOORD2, float3 color:TEXCOORD3, float3 finalcolor:TEXCOORD4) 
			{
				float3 dx = ddx_fine( position );
				float3 dy = ddy_fine( position );
				float3 c = voronoi(color+instance.xxx);
				if (c.r<_ParticleOpacity) discard;
				structurePS ps;
				half3 specular;
				half specularMonochrome;
				half3 diffuseColor = DiffuseAndSpecularFromMetallic( 0.0, 0.0, specular, specularMonochrome );
				ps.albedo = half4( 0,0,0,0 );
				ps.specular = half4( 0,0,0,0 );
				ps.normal = half4( 0,0,0,0 );
				if (_DiffuseShading == 1.0)
					ps.emission = half4(max(dot(normalize(_WorldSpaceLightPos0).xyz, 1.0 - normalize(cross(dx,dy))),0.0).xxx * finalcolor + float3(0.05,0.05,0.05), 1.0);
				else
					ps.emission = half4(finalcolor, 1.0);
				return ps;          
			}
			ENDCG
		}
		
	}
}