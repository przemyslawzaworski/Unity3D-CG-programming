// Assign material with this shader to any gameobject. You can also seamlessly join material instances with proper offsets.
// For example add to 3D scene two cubes, both with default scale and rotation. Next, set position to first cube (0,0,0) and second cube (1,0,0).
// To first cube assign material1 with shader parameters (Offset X=0,Offset Y=0). 
// To second cube assign material2 with shader parameters (Offset X=-2,Offset Y=0). 
// Source: https://www.shadertoy.com/view/XtsyRr
Shader "Concrete"
{
	Properties
	{
		_offsetX("Offset X", Float) = 0.0
		_offsetY("Offset Y", Float) = 0.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			float _offsetX, _offsetY;
			static const float rotation = 180.0;
			static const float offsetIntensity = 5.5;

			float random (float2 n)
			{ 
				return frac(sin(dot(n.xy,float2(12.9898,78.233)))*43758.5453123); 
			}

			float noise (float2 st)
			{
				float2 i = floor(st);
				float2 f = frac(st);
				float a = random(i);
				float b = random(i + float2(1.0, 0.0));
				float c = random(i + float2(0.0, 1.0));
				float d = random(i + float2(1.0, 1.0));
				float2 u = f*f*(3.0-2.0*f);
				return lerp(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
			}

			float fbm (float2 st)
			{
				float value = 0.0;
				float amplitude = 1.;
				float frequency = 2.;
				for (int i = 0; i <16; i++)
				{
					value += amplitude * noise(st);
					st *= 3.;
					amplitude *= .5;
				}    
				return value;
			}

			float4 mainNoise(float2 uv)
			{
				float d = fbm(uv+(fbm(uv)*offsetIntensity));
				return float4(d,d,d,1.0);
			}

			float2 rotate(float2 uv, float a)
			{
				return float2(uv.x*cos(a)-uv.y*sin(a),uv.y*cos(a)+uv.x*sin(a));
			}
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float f = 0.0;
				float2 o = float2(_offsetX,_offsetY);
				float2 uv = float2(2.0*ps.uv.xy-1.0)+o;
				f = 0.5000 * mainNoise( 1.0*uv ).r; uv = rotate(uv, radians(-rotation * 0.1));
				f += 0.2500 * mainNoise( 4.0*uv ).r; uv = rotate(uv, radians(-rotation * 0.3));
				f += 0.02500 * mainNoise( 8.0*uv ).r; uv = rotate(uv, radians(rotation * 0.5));
				f += 0.00125 * mainNoise( 16.0*uv ).r; uv = rotate(uv, radians(rotation * 1.0));    
				f += 0.0250 * mainNoise( 32.0*uv ).r; uv = rotate(uv, radians(rotation * 0.4));
				f += 0.0150 * mainNoise( 64.0*uv ).r; uv = rotate(uv, radians(rotation * 0.4));   
				f = 0.8*f;     
				return float4( float3(f,f,f), 1.0 );			
			}
			
			ENDCG
		}
	}
}