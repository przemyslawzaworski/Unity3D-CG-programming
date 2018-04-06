//Reference book: 
//A. Boreskov, E. Shikin - "Computer Graphics: From Pixels to Programmable Graphics Hardware"
//https://github.com/przemyslawzaworski

Shader "Strauss Lighting Model"
{
	Properties
	{
		_smoothness ("Smoothness",Range(0.0,1.0)) = 0.5
		_transparency ("Transparency",Range(0.0,1.0)) = 0.3
		_metalness("Metalness",Range(0.0,1.0)) = 1.0
		_color ("Color", Color) = (1,1,1,0)
	}
	Subshader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct structure
			{
				float4 screen_vertex : SV_POSITION;
				float3 world_normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 world_vertex : TEXCOORD1;
			};

			float _smoothness,_metalness,_transparency;
			float4 _color;

			float fresnel(float x) 
			{
				float kf = 1.12;		
				float dx = x - kf;
				float d1 = 1.0 - kf;
				float kf2 = kf * kf;
				float n = 1.0/(dx*dx)-1.0/kf2;
				float m = 1.0/(d1*d1)-1.0/kf2;
				return n/m;
			}

			float shadow(float x) 
			{
				float ks = 1.01;			
				float dx = x - ks;
				float d1 = 1.0 - ks;
				float ks2 = ks * ks;
				float n = 1.0/(d1*d1)-1.0/(dx*dx);
				float m = 1.0/(d1*d1)-1.0/ks2;
				return n/m;
			}

			float4 strauss(float3 n, float3 v, float3 l) 
			{
				float3 h = reflect(l, n);
				float nl = dot(n, l);
				float nv = dot(n, v);
				float hv = dot(h, v);
				float f = fresnel(nl);
				float s3 = _smoothness * _smoothness * _smoothness;
				float Rd = (1.0 - s3) * (1.0 - _transparency);
				float d = (1.0 - _metalness * _smoothness);
				float3 diffuse = nl * d * Rd * _color.rgb;
				float r = (1.0 - _transparency) - Rd;
				float j = f * shadow(nl) * shadow(nv);
				float k = 0.1;
				float reflect = min(1.0, r + j * (r + k));
				float3 C1 = float3(1.0, 1.0, 1.0);
				float3 Cs = C1 + _metalness * (1.0 - f) * (_color - C1);
				float3 specular = Cs * reflect;
				specular *= pow(-hv, 3.0 / (1.0 - _smoothness));
				diffuse = max(float3(0.0,0.0,0.0), diffuse);
				specular = max(float3(0.0,0.0,0.0), specular);
				return float4(diffuse + specular, 1.0);			
			}		
			
			structure vertex_shader (float4 vertex:POSITION, float3 normal:NORMAL, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.screen_vertex = UnityObjectToClipPos (vertex);
				vs.world_vertex = mul(unity_ObjectToWorld, vertex);
				vs.world_normal = normalize(mul((float3x3)unity_ObjectToWorld,normal));
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{
				float2 uv = ps.uv.xy;            
				float3 n = ps.world_normal;
				float3 l = normalize(_WorldSpaceLightPos0.xyz);
				float3 v = normalize(ps.world_vertex - _WorldSpaceCameraPos.xyz);
				float4 color = strauss (n,v,l);
				return color;		
			}
			ENDCG
		}
		
		Pass
		{
			Tags{ "LightMode" = "ShadowCaster" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
					
			float4 vertex_shader (float4 vertex:POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (void) : COLOR
			{
				return 0;		
			}
			ENDCG
		}
		
	}
}