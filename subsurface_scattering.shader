//reference: https://www.shadertoy.com/view/ldcGWH
//In Unity3D editor, add 3D Object/Quad to Main Camera, then bind material with shader to the quad. Set quad position at (x=0 ; y=0; z=0.4;). Play.

Shader "Subsurface Scattering"
{
	Properties
	{
		density("Density",Range(0.0,2.0)) = 0.4			
		ss_power("Power",Range(0.0,10.0)) = 3.0
		ss_scattering("Scattering",Range(0.0,2.0)) = 0.4	
		ss_offset("Offset",Range(0.0,2.0)) = 0.5
		ss_intensity("Intensity",Range(0.0,5.0)) = 1.0	
		ss_mix("Mix",Range(0.0,2.0)) = 1.0		
		ss_color("SSS Color",Color) = (0.85, 0.05, 0.2, 0.0)		
		surfaceThickness("Thickness",Range(0.0,0.02)) = 0.008		
		rimCol("Rim Color",Color) = (1.0, 1.0, 1.0, 1.0)
		rimPow("Rim Power",Range(0.0,5.0)) = 2.5	
		rimAmount("Rim Amount",Range(0.0,2.0)) = 1.0
		F("Fresnel",Range(0.0,5.0)) = 2.2
		LP("Light Position",Vector) = (14.0, 10.0, 29.0, 1.0)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_vertex : TEXCOORD1;
			};
	
			float density ;
			float ss_power ; 
			float ss_scattering;
			float ss_offset;
			float ss_intensity;
			float ss_mix;
			float4 ss_color;
			float surfaceThickness ;
			float4 rimCol;
			float rimPow;
			float rimAmount;
			float F;
			float4 LP;

			float hash(float2 co)
			{
				return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
			}

			float map(float3 p)
			{
				return length(p)-1.0;
			}

			float3 set_normal (float3 p)
			{
				float3 x = float3 (0.001,0.00,0.00);
				float3 y = float3 (0.00,0.001,0.00);
				float3 z = float3 (0.00,0.00,0.001);
				return normalize(float3(map(p+x)-map(p-x), map(p+y)-map(p-y), map(p+z)-map(p-z))); 
			}

			float subsurface_scattering (float3 ro, float3 rd, float3 light, float3 n)
			{
				float len = 0.0;
				const float samples = 12.0;
				const float sqs = sqrt(samples);				
				for (float s = -samples / 2.0; s < samples / 2.0; s+= 1.0)
				{
					float3 p = ro + (-n * surfaceThickness);
					float3 ld = light;				
					ld.x += fmod(abs(s), sqs) * ss_scattering * sign(s);
					ld.y += (s / sqs) * ss_scattering;				
					ld.x += hash(p.xy * s) * ss_scattering;
					ld.y += hash(p.yx * s) * ss_scattering;
					ld.z += hash(p.zx * s) * ss_scattering;
					ld = normalize(ld);
					float3 dir = ld;
					for (int i = 0; i < 50; ++i)
					{
						float d = map(p);
						if(d < 0.0) d = min(d, -0.0001);
						if(d >= 0.0) break;
						dir = normalize(ld);
						p += abs(d * 0.5) * dir;  
					}
					len += length(ro - p);
				}	
				return len / samples;
			}

			float4 lighting (float3 ro, float3 rd)
			{
				float4 AmbientLight = float4(0.0,0.0,0.0,0.0);
				float3 LightDirection = normalize( LP.xyz );
				float3 NormalDirection = set_normal(ro);
				float Diffuse = saturate(dot(NormalDirection, LightDirection));
				float3 Reflection = reflect(-LightDirection, NormalDirection);
				float Rim = pow(saturate(1.0 - dot(Reflection, -rd)),rimPow);
				float fresnel = Rim + F * (1.0 - Rim);
				float4 color = AmbientLight + fresnel * rimCol * rimAmount * Diffuse;     
				float s = subsurface_scattering(ro, rd, LightDirection, NormalDirection);
				s = pow(exp(ss_offset -s * density),ss_power);
				float4 sscol = s * ss_color * ss_intensity;
				sscol = lerp(sscol, ss_color, 1.0 - ss_mix);	   
				return color+sscol;
			}

			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001) return lighting (ro,rd);
					ro+=t*rd;
				}
				return 0;
			}
			
			custom_type vertex_shader (float4 vertex : POSITION)
			{
				custom_type vs;
				vs.screen_vertex = mul (UNITY_MATRIX_MVP, vertex);
				vs.world_vertex = mul (_Object2World, vertex);
				return vs;
			}

			float4 pixel_shader (custom_type ps ) : SV_TARGET
			{
				float3 worldPosition = ps.world_vertex;
				float3 viewDirection = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				return raymarch(worldPosition,viewDirection);
			}

			ENDCG

		}
	}
}