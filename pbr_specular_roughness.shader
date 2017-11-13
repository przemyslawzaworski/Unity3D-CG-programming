//reference: http://www.reptoidgames.com/goodies/PBR%20Dual%20Masked.shader
Shader "PBR specular roughness workflow" 
{
	Properties 
	{
		_Albedo ("Albedo Map (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map (RGB)", 2D) = "bump" {}
		_SpecularMap ("Specular Map (RGB)", 2D) = "white" {}
		_Roughness ("Roughness Map (R)", 2D) = "black" {}
	}
	SubShader 
	{
		Pass 
		{
			Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			#define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
			#include "UnityPBSLighting.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
			#pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
			uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
			uniform sampler2D _SpecularMap; uniform float4 _SpecularMap_ST;
			uniform sampler2D _Albedo; uniform float4 _Albedo_ST;
			uniform sampler2D _Roughness; uniform float4 _Roughness_ST;
			
			struct VertexInput 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};
			
			struct VertexOutput 
			{
				float4 vertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
				float4 posWorld : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
				float3 tangentDir : TEXCOORD5;
				float3 bitangentDir : TEXCOORD6;        
				float4 lightmap : TEXCOORD7;             
			};

			fixed3 UnpackNormals(fixed4 packednormal)
			{
				packednormal.x *= packednormal.w;
				fixed3 normal;
				normal.xy = packednormal.xy * 2 - 1;
				normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
				return normal;
			}
						
			half VisibilitySmith(half NdotL, half NdotV, half roughness)
			{
				half a = roughness;
				half a2  = a * a;
				half lambdaV = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
				half lambdaL  = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);
				return 0.5f / (lambdaV + lambdaL + 1e-5f);  
			}
			
			half DistributionGGX(half NdotH, half roughness)
			{
				half a2 = roughness * roughness;
				half d = (NdotH * a2 - NdotH) * NdotH + 1.0f; 
				return  0.31830988618f * a2 / (d * d + 1e-7f);                                            
			}

			half3 EnergyConservation (half3 albedo, half3 specular, out half oneMinusReflectivity)
			{
				oneMinusReflectivity = 1.0 - max (max (specular.r, specular.g), specular.b);
				return albedo * oneMinusReflectivity;
			}
			
			VertexOutput vertex_shader (VertexInput v) 
			{
				VertexOutput o = (VertexOutput)0;
				o.uv0 = v.uv0;
				#ifdef LIGHTMAP_ON
					o.lightmap.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					o.lightmap.zw = 0;
				#elif UNITY_SHOULD_SAMPLE_SH
				#endif
				#ifdef DYNAMICLIGHTMAP_ON
					o.lightmap.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
				o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 lightColor = _LightColor0.rgb;
				o.vertex = UnityObjectToClipPos( v.vertex );
				return o;
			}
			
			float4 pixel_shader (VertexOutput i) : COLOR 
			{
				i.normalDir = normalize(i.normalDir);
				float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 normalLocal = UnpackNormals(tex2D(_BumpMap,i.uv0));
				float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); 
				float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;
				float3 halfDirection = normalize(viewDirection+lightDirection);
				float attenuation = 1.0;
				float3 attenColor = attenuation * _LightColor0.xyz;
				float Pi = 3.141592654;
				float InvPi = 0.31830988618;
				float4 _Roughness_var = tex2D(_Roughness,i.uv0);
				float gloss = 1.0 - _Roughness_var.r; 
				float perceptualRoughness = _Roughness_var.r;
				float roughness = perceptualRoughness * perceptualRoughness;
				float specPow = exp2( gloss * 10.0 + 1.0 );
				UnityLight light;
				#ifdef LIGHTMAP_OFF
					light.color = lightColor;
					light.dir = lightDirection;
					light.ndotl = LambertTerm (normalDirection, light.dir);
				#else
					light.color = half3(0.f, 0.f, 0.f);
					light.ndotl = 0.0f;
					light.dir = half3(0.f, 0.f, 0.f);
				#endif
				UnityGIInput d;
				d.light = light;
				d.worldPos = i.posWorld.xyz;
				d.worldViewDir = viewDirection;
				d.atten = attenuation;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					d.ambient = 0;
					d.lightmapUV = i.lightmap;
				#else
					d.ambient = i.lightmap;
				#endif
				#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
					d.boxMin[0] = unity_SpecCube0_BoxMin;
					d.boxMin[1] = unity_SpecCube1_BoxMin;
				#endif
				#if UNITY_SPECCUBE_BOX_PROJECTION
					d.boxMax[0] = unity_SpecCube0_BoxMax;
					d.boxMax[1] = unity_SpecCube1_BoxMax;
					d.probePosition[0] = unity_SpecCube0_ProbePosition;
					d.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif
				d.probeHDR[0] = unity_SpecCube0_HDR;
				d.probeHDR[1] = unity_SpecCube1_HDR;
				Unity_GlossyEnvironmentData ugls_en_data;
				ugls_en_data.roughness = 1.0 - gloss;
				ugls_en_data.reflUVW = viewReflectDirection;
				UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
				lightDirection = gi.light.dir;
				lightColor = gi.light.color;
				float NdotL = saturate(dot( normalDirection, lightDirection ));
				float LdotH = saturate(dot(lightDirection, halfDirection));
				float3 specularColor =tex2D(_SpecularMap,i.uv0).xyz;
				float specularMonochrome;
				float3 diffuseColor = tex2D(_Albedo,i.uv0).xyz;
				diffuseColor = EnergyConservation(diffuseColor, specularColor, specularMonochrome);
				specularMonochrome = 1.0-specularMonochrome;
				float NdotV = abs(dot( normalDirection, viewDirection ));
				float NdotH = saturate(dot( normalDirection, halfDirection ));
				float VdotH = saturate(dot( viewDirection, halfDirection ));
				float visTerm = VisibilitySmith( NdotL, NdotV, roughness );
				float normTerm = DistributionGGX(NdotH, roughness);
				float specularPBL = (visTerm*normTerm) * UNITY_PI;
				specularPBL = sqrt(max(1e-4h, specularPBL));
				specularPBL = max(0, specularPBL * NdotL);
				half s = 1.0-0.28*roughness*perceptualRoughness;
				specularPBL *= any(specularColor) ? 1.0 : 0.0;
				float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
				half grazingTerm = saturate( gloss + specularMonochrome );
				float3 indirectSpecular = (gi.indirect.specular)*FresnelLerp (specularColor, grazingTerm, NdotV);
				indirectSpecular *= s;
				float3 specular = directSpecular + indirectSpecular;
				NdotL = saturate(dot( normalDirection, lightDirection ));
				half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
				float nlPow5 = Pow5(1-NdotL);
				float nvPow5 = Pow5(1-NdotV);
				float3 directDiffuse = ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL) * attenColor;
				float3 indirectDiffuse = gi.indirect.diffuse;
				diffuseColor *= 1-specularMonochrome;
				float3 color = (directDiffuse + indirectDiffuse)*diffuseColor+specular;
				return float4(color,1);
			}
			ENDCG
		}
	}
}
