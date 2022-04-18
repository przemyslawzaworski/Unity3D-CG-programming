// Line Integral Convolution
Shader "Fur Texture Generator"
{
	Properties
	{
		[KeywordEnum(FBM0,Fbm1,Fbm2,Fbm3,Fbm4,Fbm5,Fbm6)] _Domain1 ("First  domain function", Int) = 4
		[KeywordEnum(FBM0,Fbm1,Fbm2,Fbm3,Fbm4,Fbm5,Fbm6)] _Domain2 ("Second domain function", Int) = 5
		[KeywordEnum(FBM0,Fbm1,Fbm2,Fbm3,Fbm4,Fbm5,Fbm6)] _Domain3 ("Third  domain function", Int) = 6
		_Colors("Base colors amount <2-4>",Int) = 4
		_A("Parameter A", Range(-10.0,10.0)) =  0.5
		_B("Parameter B", Range(-10.0,10.0)) =  2.0
		_C("Parameter C", Range(-10.0,10.0)) =  2.8
		_D("Parameter D", Range(-10.0,10.0)) = -1.0
		_E("Parameter E", Range(0.00,2.0)) = 0.0
		_F("Parameter F", Range(0.00,2.0)) = 2.0
		_G("Parameter G", Range(-10.0,10.0)) = 10.0
		_H("Parameter H", Range(-10.0,10.0)) = -3.0
		_I("Parameter I", Range(0.005, 0.05)) = 0.01
		_S("Parameter S", Range(-10.0,10.0)) =  0.5
		_UVScale("UV Scale", Range(0.0,2.0)) =  1.0
		_Wind("Wind", Range(0.0,1.0)) =  0.5
		_FurLength("Fur Length", Range(1, 64)) = 18
		_Color1 ("Color 1", Color) = (1.0, 1.0, 1.0, 1.0)
		_Color2 ("Color 2", Color) = (1.0, 1.0, 1.0, 1.0)
		_Color3 ("Color 3", Color) = (1.0, 0.5, 0.0, 1.0)
		_Color4 ("Color 4", Color) = (0.3, 0.2, 0.0, 1.0)
		_LightDir ("Light Direction", Vector) = (0.5, 0.5, -1.0, 1)
		_NormalStrength("Normal Strength", Range(0.0, 50.0)) = 15.0
		[Toggle] _UseNormal ("Use Normal Map", Float) = 1
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler2D _RenderTexture;
			int _Colors, _Domain1, _Domain2, _Domain3, _FurLength;
			float _A, _B, _C, _D, _E, _F, _G, _H, _I, _S, _UVScale, _Wind;
			float4 _Color1, _Color2, _Color3, _Color4;

			static const float2x2 _M = float2x2( _A, _B, _C, _D );

			float Hash (float2 n) 
			{ 
				return frac(sin(dot(n, float2(95.43583, 93.323197))) * 65536.32);
			}

			float Noise (float2 p)
			{
				float2 i = floor(p);
				float2 u = frac(p);
				u = u*u*(3.0-2.0*u);
				float2 d = float2 (1.0,0.0);
				float r = lerp(lerp(Hash(i),Hash(i+d.xy),u.x),lerp(Hash(i+d.yx),Hash(i+d.xx),u.x),u.y);
				return r*r;
			}

			float Fbm1( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p ));
				return f;
			}

			float Fbm2( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p )); p = p*2.02; p = mul(p,_M);
				f += 0.250000*(_E+_F*Noise( p ));
				return f;
			}

			float Fbm3( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p )); p = p*2.02; p = mul(p,_M);
				f += 0.250000*(_E+_F*Noise( p )); p = p*2.03; p = mul(p,_M);
				f += 0.125000*(_E+_F*Noise( p )); 
				return f;
			}

			float Fbm4( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p )); p = p*2.02; p = mul(p,_M);
				f += 0.250000*(_E+_F*Noise( p )); p = p*2.03; p = mul(p,_M);
				f += 0.125000*(_E+_F*Noise( p )); p = p*2.01; p = mul(p,_M);
				f += 0.062500*(_E+_F*Noise( p ));
				return f;
			}

			float Fbm5( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p )); p = p*2.02; p = mul(p,_M);
				f += 0.250000*(_E+_F*Noise( p )); p = p*2.03; p = mul(p,_M);
				f += 0.125000*(_E+_F*Noise( p )); p = p*2.01; p = mul(p,_M);
				f += 0.062500*(_E+_F*Noise( p )); p = p*2.04; p = mul(p,_M);
				f += 0.031250*(_E+_F*Noise( p )); 
				return f;
			}

			float Fbm6( float2 p )
			{
				float f = 0.0;
				f += 0.500000*(_E+_F*Noise( p )); p = p*2.02; p = mul(p,_M);
				f += 0.250000*(_E+_F*Noise( p )); p = p*2.03; p = mul(p,_M);
				f += 0.125000*(_E+_F*Noise( p )); p = p*2.01; p = mul(p,_M);
				f += 0.062500*(_E+_F*Noise( p )); p = p*2.04; p = mul(p,_M);
				f += 0.031250*(_E+_F*Noise( p )); p = p*2.01; p = mul(p,_M);
				f += 0.015625*(_E+_F*Noise( p ));
				return f;
			}

			float DomainWarping( float2 p )
			{
				float d1, d2;
				if (_Domain1==1) d1 = Fbm1(p);
				else
				if (_Domain1==2) d1 = Fbm2(p);
				else
				if (_Domain1==3) d1 = Fbm3(p);
				else
				if (_Domain1==4) d1 = Fbm4(p);
				else
				if (_Domain1==5) d1 = Fbm5(p);
				else
				d1 = Fbm6(p);

				if (_Domain2==1) d2 = Fbm1(p+float2(_G,_H));
				else
				if (_Domain2==2) d2 = Fbm2(p+float2(_G,_H));
				else
				if (_Domain2==3) d2 = Fbm3(p+float2(_G,_H));
				else
				if (_Domain2==4) d2 = Fbm4(p+float2(_G,_H));
				else
				if (_Domain2==5) d2 = Fbm5(p+float2(_G,_H));
				else
				d2 = Fbm6(p+float2(_G,_H));
				
				float2 q = float2(d1, d2);

				if (_Domain3==1) return Fbm1( p + _S*q );
				else
				if (_Domain3==2) return Fbm2( p + _S*q );
				else
				if (_Domain3==3) return Fbm3( p + _S*q );
				else
				if (_Domain3==4) return Fbm4( p + _S*q );
				else
				if (_Domain3==5) return Fbm5( p + _S*q );
				else
				return Fbm6( p + _S*q );
			}

			float2 Hash2D( float2 x )
			{
				float2 k = float2( 0.3183099, 0.3678794 );
				x = x*k + k.yx;
				return -1.0 + 2.0*frac(16.0 * k * frac( x.x*x.y*(x.x+x.y)));
			}

			float GradientNoise(float2 p)
			{
				float2 i = floor( p );
				float2 f = frac( p );
				float2 u = smoothstep(0., 1., f);
				float2 a = Hash2D(i);
				float2 b = Hash2D(i + float2(1.,0.));
				float2 c = Hash2D(i + float2(.0,1.));
				float2 d = Hash2D(i + float2(1,1));
				float nse = lerp(lerp( dot( a, f - float2(0.0,0.0)),
					dot( b, f - float2(1.0,0.0)), u.x),
					lerp( dot( c, f - float2(0.0,1.0) ), 
					dot( d, f - float2(1,1)), u.x), u.y);
				return nse + 0.5;
			}

			float Fbm(float2 p, int octaves)
			{
				float a = 1.0;
				float n = 0.0;
				for(int i = 0; i < octaves; i++)
				{
					n += GradientNoise(p) * a;
					p *= 2.0;
					a *= 0.5;
				}
				return n;
			}

			float4 VSMain (float4 vertex:POSITION, inout float2 texcoord:TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 Surface (float2 uv)
			{
				float4 cache = (float4) 0;
				float result = DomainWarping(uv);
				if (_Colors==2) 
				{
					return lerp(_Color1, _Color2, result);
				}
				else if (_Colors==3)
				{
					cache = lerp(_Color1, _Color2, result);
					return  lerp(cache, _Color3, result);
				}
				else
				{
					cache = lerp(_Color1, _Color2, result);
					cache = lerp(cache, _Color3, result);
					return lerp(cache, _Color4, result);
				}
			}

			float4 PSMain (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0 ) : SV_TARGET
			{
				float2 uv = -float2(2.0 * texcoord - 1.0) * _UVScale;
				float3 accumulation = float3(0., 0., 0.);
				int count = _FurLength;
				float s = 6., h = _Time.g * _Wind;
				for(int i = 0; i < count; i++)
				{
					float2 p = _I * float2(cos(uv.y * s + h), sin(uv.x * s + h));
					float f = Fbm(p * 4.0, 4.0) * 25.0;
					accumulation += Surface(uv).xyz;
					uv += float2(cos(f), sin(f)) * 0.0025;
				}
				accumulation /= (float)count;
				return float4(accumulation, 1.0);
			}

			ENDCG
		}
		Pass
		{ 
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			sampler2D _RenderTexture;
			float _UseNormal, _NormalStrength;
			float4 _LightDir;

			float3 RecalculateNormals(float2 uv, float power)
			{
				float h = 0.001;
				float dx = tex2D(_RenderTexture, uv).r - tex2D(_RenderTexture, uv + float2(h, .0)).r;
				float dy = tex2D(_RenderTexture, uv).r - tex2D(_RenderTexture, uv + float2(0., h)).r;
				return normalize(float3(0.0, 0.0, -1.0) + float3(dx, dy, 0.0) * power);
			}

			float4 VSMain (float4 vertex:POSITION, inout float2 texcoord:TEXCOORD0) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex:SV_POSITION, float2 texcoord:TEXCOORD0 ) : SV_TARGET
			{
				float2 uv = texcoord;
				float3 source = tex2D(_RenderTexture, texcoord).rgb;
				float3 normalDir = RecalculateNormals(texcoord, _NormalStrength);
				float diffuse = max(dot(normalDir, normalize(_LightDir.xyz)), 0.0) + 0.5;
				float3 color = (_UseNormal > 0.0) ? source * diffuse : source;
				color = pow(color, (float3) 3.0);
				color = (_UseNormal > 0.0) ? 1.0 - exp(-color) : color;
				return float4(color, 1.0);
			}
			ENDCG
		}
	}
}