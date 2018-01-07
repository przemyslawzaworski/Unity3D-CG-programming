//Reference: https://www.shadertoy.com/view/lss3DS
//License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//Translated from ShaderToy to Unity by Przemyslaw Zaworski, 07.01.2018
//See also: https://www.alanzucconi.com/2017/10/10/atmospheric-scattering-1/

//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. 
//Set quad position at (x=0 ; y=0; z=0.4;). Apply fly script to the camera. Play.
//Shader in current version is "independent" from scene content. For further improvements and seamless
//full integration with Unity scene, see "ocean.cs" and "ocean.shader" from 
//https://github.com/przemyslawzaworski/Unity3D-CG-programming
//to see example how merge raymarching shaders with Unity game objects.

Shader "Atmospheric Scattering"
{
	Properties
	{	
		speed("Speed",Range(0.0,5.0)) = 1.0	
		sun_intensity ("Sun intensity",Range(1.0,40.0)) = 20.0
		rayleigh ("Rayleigh scale",Range(10.0,10000.0)) = 7994.0
		mie ("Mie scale",Range(10.0,5000.0)) = 1200.0
		exposure("Exposure",Range(10.0,100.0)) = 60.0
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
		
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
	
			float speed, sun_intensity, rayleigh, mie, exposure;
			static const float PI = 3.14159265358979323846;
			static const float PI_2 = 1.57079632679489661923;
			static const float PI_4 = 0.785398163397448309616;
			static const int SKYLIGHT_NB_VIEWDIR_SAMPLES = 12;
			static const int SKYLIGHT_NB_SUNDIR_SAMPLES = 8;
			
			struct planet_t
			{
				float rs;  		// sea level radius
				float ra; 		// atmosphere radius
				float3  beta_r;	// rayleigh scattering coefs at sea level
				float3  beta_m; 	// mie scattering coefs at sea level
				float sh_r; 	// rayleigh scale height
				float sh_m; 	// mie scale height
			};

			struct sun_t
			{  
				float i;		// sun intensity
				float mc;	    // mean cosine
				float azi; 		// azimuth
				float alt; 		// altitude
				float ad; 		// angular diameter (between 0.5244 and 5.422 for our sun)
				float3 color;
			};

			planet_t earth;
			sun_t sun;	

			void init ()
			{			
				earth.rs = 6360.0e3;
				earth.ra = 6420.0e3;
				earth.beta_r = float3(5.5e-6, 13.0e-6, 22.1e-6);
				earth.beta_m = float3(21.0e-6,21.0e-6,21.0e-6);
				earth.sh_r = rayleigh;
				earth.sh_m = mie;
				sun.i= sun_intensity;
				sun.mc = 0.76;
				sun.azi = 5.0;
				sun.alt = PI_2;
				sun.ad = 0.53;
				sun.color = float3(1.0, 1.0, 1.0);			
			}
	
			bool intersect_with_atmosphere(in float3 ro, in float3 rd, in planet_t planet, out float tr)
			{
				float c = length(ro);   // distance from center of the planet 
				float3 up_dir = ro / c;
				float beta = PI - acos(dot(rd, up_dir)); 
				float sb = sin(beta);
				float b = planet.ra;
				float bt = planet.rs - 10.0;	
				tr = sqrt((b * b) - (c * c) * (sb * sb)) + c * cos(beta); // sinus law	
				if (sqrt((bt * bt) - (c * c) * (sb * sb)) + c * cos(beta) > 0.0) return false;
				return true;
			}

			float compute_sun_visibility(sun_t sun, float alt)
			{
				float vap = 0.0;
				float h, a;
				float vvp = clamp((0.5 + alt / sun.ad), 0.0, 1.0);
				if (vvp == 0.0)
				{
					return 0.0;
				}
				else if (vvp == 1.0)
				{
					return 1.0;
				}
				bool is_sup;
				if (vvp > 0.5)
				{
					is_sup = true;
					h = (vvp - 0.5) * 2.0;
				}
				else
				{
					is_sup = false;
					h = (0.5 - vvp) * 2.0;
				}
				float alpha = acos(h) * 2.0;
				a = (alpha - sin(alpha)) / (2.0 * PI);	
				if (is_sup)
				{
					vap = 1.0 - a;
				}
				else
				{
					vap = a;
				}
				return vap;
			}
			
			float3 compute_sky_light(float3 ro,float3 rd, planet_t planet, sun_t sun, float ground)
			{
				float t1;
				float3 temp =ro;
				if (!intersect_with_atmosphere(ro, rd, planet, t1) || t1 < 0.0)
					return float3(ground,ground,ground);  //ground color  
				float sl = t1 / float(SKYLIGHT_NB_VIEWDIR_SAMPLES); 
				float t = 0.0;	
				float calt = cos(sun.alt);
				float3 sun_dir = float3(cos(sun.azi) * calt,
				sin(sun.alt),
				sin(sun.azi) * calt);
				float mu = dot(rd, sun_dir);
				float mu2 = mu * mu;
				float mc2 = sun.mc * sun.mc;
				float3 sumr = float3(0.0,0.0,0.0);
				float odr = 0.0; // optical depth
				float phase_r = (3.0 / (16.0 * PI)) * (1.0 + mu2);
				float3 summ = float3(0.0,0.0,0.0);
				float odm = 0.0; // optical depth
				float phase_m = ((3.0/(8.0*PI))*((1.0-mc2)*(1.0 + mu2)))/((2.0+mc2)*pow(1.0+mc2-2.0*sun.mc*mu,1.5)); 
				for (int i = 0; i < SKYLIGHT_NB_VIEWDIR_SAMPLES; ++i)
				{
					float3 sp = ro + rd * (t + 0.5 * sl);
					float h = length(sp) - planet.rs;
					float hr = exp(-h / planet.sh_r) * sl;
					odr += hr;
					float hm = exp(-h / planet.sh_m) * sl;
					odm += hm;
					float tm;
					float sp_alt = PI_2 - asin(planet.rs / length(sp));
					sp_alt += acos(normalize(sp).y) + sun.alt;
					float coef = compute_sun_visibility(sun, sp_alt);
					if (intersect_with_atmosphere(sp, sun_dir, planet, tm) || coef > 0.0)
					{
						float sll = tm / float(SKYLIGHT_NB_SUNDIR_SAMPLES);
						float tl = 0.0;
						float odlr = 0.0, odlm = 0.0;
						for (int j = 0; j < SKYLIGHT_NB_SUNDIR_SAMPLES; ++j)
						{
							float3 spl = sp + sun_dir * (tl + 0.5 * sll);
							float spl_alt = PI_2 - asin(planet.rs / length(spl));
							spl_alt += acos(normalize(spl).y) + sun.alt;
							float coefl = compute_sun_visibility(sun, spl_alt);
							float hl = length(spl) - planet.rs;
							odlr += exp(-hl / planet.sh_r) * sll * (1.0 - log(coefl + 0.000001));
							odlm += exp(-hl / planet.sh_m) * sll * (1.0 - log(coefl + 0.000001));
							tl += sll;
						}
						float3 tau = planet.beta_r * (odr + odlr) + planet.beta_m * 1.05 * (odm + odlm);
						float3 attenuation = float3(exp(-tau.x), exp(-tau.y), exp(-tau.z));
						sumr +=  hr * attenuation * coef;
						summ +=  hm * attenuation * coef;
					}
					t += sl;
				}
				return sun.i * (sumr * phase_r * planet.beta_r + summ * phase_m * planet.beta_m);
			}

			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul (unity_ObjectToWorld, vertex);
				return vs;
			}
		
			float4 pixel_shader (structure ps) : SV_TARGET
			{
				init();
				float2 iResolution = _ScreenParams.xy;
				float2 fragCoord = ps.screen_vertex.xy;				
				float2 q = fragCoord.xy / iResolution.xy;
				float2 p = -1.0 + 2.0*q;
				p.x *= iResolution.x / iResolution.y;
				float3 c_position = ps.world_vertex;
				float3 rd = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				sun.alt = -0.1 + 1.2 * PI_4 * (0.5 + cos(0.38*_Time.g*speed) / 2.0);
				float3 gp = c_position + float3(0.0, earth.rs + 1.0, 0.0);
				float3 res = compute_sky_light(gp, rd, earth, sun,sun.alt*2.0);
				float crush = 0.6;
				float frange = 7.8;
				res = log2(1.0+res*exposure);
				res = smoothstep(crush, frange, res);
				res = res*res*res*(res*(res*6.0 - 15.0) + 10.0);	
				return float4(res, 1.0);
			}
			ENDCG
		}
	}
}