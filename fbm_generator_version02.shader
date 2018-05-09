//2D Gradient Perlin Noise

Shader "FBM Generator version 2"
{
	Properties
	{
		_offsetX ("OffsetX",Float) = 0.0
		_offsetY ("OffsetY",Float) = 0.0		
		_octaves ("Octaves",Int) = 7
		_lacunarity("Lacunarity", Range( 1.0 , 5.0)) = 2
		_gain("Gain", Range( 0.0 , 1.0)) = 0.5
		_value("Value", Range( -2.0 , 2.0)) = 0.0
		_amplitude("Amplitude", Range( 0.0 , 5.0)) = 1.5
		_frequency("Frequency", Range( 0.0 , 6.0)) = 2.0
		_power("Power", Range( 0.1 , 5.0)) = 1.0
		_scale("Scale", Float) = 1.0
		_color ("Color", Color) = (1.0,1.0,1.0,1.0)		
		[Toggle] _monochromatic("Monochromatic", Float) = 0
		_range("Monochromatic Range", Range( 0.0 , 1.0)) = 0.5		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float _octaves,_lacunarity,_gain,_value,_amplitude,_frequency, _offsetX, _offsetY, _power, _scale, _monochromatic, _range;
			float4 _color;
			
			float fbm( float2 p )
			{
				p = p * _scale + float2(_offsetX,_offsetY);
				for( int i = 0; i < _octaves; i++ )
				{
					float2 i = floor( p * _frequency );
					float2 f = frac( p * _frequency );       
					float2 t = f * f * f * ( f * ( f * 6.0 - 15.0 ) + 10.0 ); 
					float2 a = i + float2( 0.0, 0.0 );
					float2 b = i + float2( 1.0, 0.0 );
					float2 c = i + float2( 0.0, 1.0 );
					float2 d = i + float2( 1.0, 1.0 );
					a = -1.0 + 2.0 * frac( sin( float2( dot( a, float2( 127.1, 311.7 ) ),dot( a, float2( 269.5,183.3 ) ) ) ) * 43758.5453123 );
					b = -1.0 + 2.0 * frac( sin( float2( dot( b, float2( 127.1, 311.7 ) ),dot( b, float2( 269.5,183.3 ) ) ) ) * 43758.5453123 );
					c = -1.0 + 2.0 * frac( sin( float2( dot( c, float2( 127.1, 311.7 ) ),dot( c, float2( 269.5,183.3 ) ) ) ) * 43758.5453123 );
					d = -1.0 + 2.0 * frac( sin( float2( dot( d, float2( 127.1, 311.7 ) ),dot( d, float2( 269.5,183.3 ) ) ) ) * 43758.5453123 );
					float A = dot( a, f - float2( 0.0, 0.0 ) );
					float B = dot( b, f - float2( 1.0, 0.0 ) );
					float C = dot( c, f - float2( 0.0, 1.0 ) );
					float D = dot( d, f - float2( 1.0, 1.0 ) );
					float noise = ( lerp( lerp( A, B, t.x ), lerp( C, D, t.x ), t.y ) );				
					_value += _amplitude * noise;
					_frequency *= _lacunarity;
					_amplitude *= _gain;
				} 
				_value = clamp( _value, -1.0, 1.0 );
				return pow(_value * 0.5 + 0.5,_power);
			}
			
			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{	
				float2 uv = ps.uv.xy ;
				float c = fbm(uv) ;
				if (_monochromatic==0.0) 
					return float4(c,c,c,c) * _color;
				else
				if (c<_range) 
					return 0;
				else 
					return 1;
			}

			ENDCG

		}
	}
}