// Usage: Windows / Rendering / Lighting Settings -> Environment / Skybox Material
// Original reference: 
// https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/simulating-sky/simulating-colors-of-the-sky

Shader "Atmospheric Scattering"
{
	Properties
	{
		_Height("Sun Altitude",Range(-5.0,5.0)) = 0.15	
		_Intensity ("Sun Intensity",Range(1.0,40.0)) = 20.0
		_Rayleigh ("Rayleigh Scale",Range(10.0,10000.0)) = 8000.0
		_Mie ("Mie Scale",Range(10.0,5000.0)) = 1200.0
		_Exposure("Exposure",Range(10.0,100.0)) = 60.0
	}
	Subshader
	{
		Tags { "RenderType" = "Background" }
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0
			
			float  _Height, _Intensity, _Rayleigh, _Mie, _Exposure;
			static const float PI = 3.14159265358979323846;
			static const float PI_2 = 1.57079632679489661923;
			static const float PI_4 = 0.785398163397448309616;
			static const int VIEWDIR_SAMPLES = 12;
			static const int SUNDIR_SAMPLES = 8;

			bool intersect(float3 ro, float3 rd, float ra, float rs, out float tr)
			{
				float c = length(ro); 
				float beta = PI - acos(dot(rd, ro / c)); 
				float sb = sin(beta);
				float b = ra;
				float bt = rs - 10.0;	
				tr = sqrt((b * b) - (c * c) * (sb * sb)) + c * cos(beta);	
				if (sqrt((bt * bt) - (c * c) * (sb * sb)) + c * cos(beta) > 0.0) return false;
				return true;
			}

			float visibility(float diameter, float alt)
			{
				float vap = 0.0, h = 0.0, a = 0.0;
				float p = clamp((0.5 + alt / diameter), 0.0, 1.0);
				if (p == 0.0)
				{
					return 0.0;
				}
				else if (p == 1.0)
				{
					return 1.0;
				}
				bool sup = false;
				if (p > 0.5)
				{
					sup = true;
					h = (p - 0.5) * 2.0;
				}
				else
				{
					sup = false;
					h = (0.5 - p) * 2.0;
				}
				float alpha = acos(h) * 2.0;
				a = (alpha - sin(alpha)) / (2.0 * PI);	
				vap = (sup) ? 1.0 - a : a;
				return vap;
			}
			
			void VSMain (inout float4 Vertex:POSITION, out float3 Point:TEXCOORD0)
			{
				Point = mul(unity_ObjectToWorld, Vertex);   // World Space coordinates
				Vertex = UnityObjectToClipPos (Vertex);   // Screen Space coordinates
			}
		
			void PSMain (float4 Vertex:POSITION, float3 Point:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float3 c = float3(0.0,0.0,0.0);
				float rs = 6360.0e3;   // Planet sea level radius
				float ra = 6420.0e3;   // Planet atmosphere radius
				float3 rsc = float3(5.5e-6, 13.0e-6, 22.1e-6);   // Rayleigh scattering coefs at sea level
				float3 msc = float3(21.0e-6, 21.0e-6, 21.0e-6);   // Mie scattering coefs at sea level
				float mean = 0.76;   // mean cosine
				float azimuth = 5.0;   // azimuth
				float diameter = 0.53;   // angular diameter (between 0.5244 and 5.422 for sun)
				float3 ro = _WorldSpaceCameraPos.xyz + float3(0.0, rs + 1.0, 0.0);
				float3 rd = normalize(Point - _WorldSpaceCameraPos.xyz);
				float s = 0.0;
				if (!intersect(ro, rd, ra, rs, s) || s < 0.0)
					c = float3(0.0,0.0,0.0); 
				float sl = s / float(VIEWDIR_SAMPLES); 
				float t = 0.0;	
				float calt = cos(_Height);
				float3 direction = float3(cos(azimuth) * calt, sin(_Height), sin(azimuth) * calt);
				float mu = dot(rd, direction);
				float mu2 = mu * mu;
				float mc2 = mean * mean;
				float3 sumr = float3(0.0,0.0,0.0);
				float odr = 0.0; 
				float phaseR = (3.0 / (16.0 * PI)) * (1.0 + mu2);
				float3 summ = float3(0.0,0.0,0.0);
				float odm = 0.0;
				float phaseM = ((3.0/(8.0*PI))*((1.0-mc2)*(1.0 + mu2)))/((2.0+mc2)*pow(1.0+mc2-2.0*mean*mu,1.5)); 
				for (int i = 0; i < VIEWDIR_SAMPLES; ++i)
				{
					float3 sp = ro + rd * (t + 0.5 * sl);
					float h = length(sp) - rs;
					float hr = exp(-h / _Rayleigh) * sl;
					odr += hr;
					float hm = exp(-h / _Mie) * sl;
					odm += hm;
					float tm;
					float sp_alt = PI_2 - asin(rs / length(sp));
					sp_alt += acos(normalize(sp).y) + _Height;
					float coef = visibility(diameter, sp_alt);
					if (intersect(sp, direction, ra, rs, tm) || coef > 0.0)
					{
						float sll = tm / float(SUNDIR_SAMPLES);
						float tl = 0.0;
						float odlr = 0.0, odlm = 0.0;
						for (int j = 0; j < SUNDIR_SAMPLES; ++j)
						{
							float3 spl = sp + direction * (tl + 0.5 * sll);
							float spl_alt = PI_2 - asin(rs / length(spl));
							spl_alt += acos(normalize(spl).y) + _Height;
							float coefl = visibility(diameter, spl_alt);
							float hl = length(spl) - rs;
							odlr += exp(-hl / _Rayleigh) * sll * (1.0 - log(coefl + 0.000001));
							odlm += exp(-hl / _Mie) * sll * (1.0 - log(coefl + 0.000001));
							tl += sll;
						}
						float3 tau = rsc * (odr + odlr) + msc * 1.05 * (odm + odlm);
						float3 attenuation = float3(exp(-tau.x), exp(-tau.y), exp(-tau.z));
						sumr +=  hr * attenuation * coef;
						summ +=  hm * attenuation * coef;
					}
					t += sl;
				}
				c = _Intensity * (sumr * phaseR * rsc + summ * phaseM * msc);
				c = log2(1.0+ c * _Exposure);
				c = smoothstep(0.6, 7.8, c);
				c = c * c * c * (c * (c * 6.0 - 15.0) + 10.0);	
				fragColor = float4(c, 1.0);
			}
			ENDCG
		}
	}
}