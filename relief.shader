Shader "Relief"
{
	Properties
	{
		_MainTex ("HeightMap", 2D) = "white" {}
		_X("Light Position X", Range(-100.0,100.0)) = 0.0
		_Y("Light Position Y", Range(-100.0,100.0)) = 0.0
		_Z("Light Position Z", Range(-100.0,100.0)) = 0.0
		_normal("Normal Precision", Float) = 0.01
		_displacement("Displacement Scale", Range(0.0,2.0)) = 1.0	
		_Light ("Light Color", Color) = (1,1,1,1)	
			
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			float _X,_Y,_Z,_normal,_height,_displacement;
			float4 _Light;
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
		
			float3x3 rotationX( float x) 
			{
				return float3x3
				(
					1.0,0.0,0.0,
					0.0,cos(x),sin(x),
					0.0,-sin(x),cos(x)
				);
			}			

			float map (float3 p)
			{
				float2 u = p.xz*0.5;
				float h = tex2Dlod(_MainTex,float4(u,0,0)).r * _displacement;
				h = p.y - h;
				return h;
			}
						
			float3 set_normal (float3 p)
			{
				float3 x = float3 (_normal,0.00,0.00);
				float3 y = float3 (0.00,_normal,0.00);
				float3 z = float3 (0.00,0.00,_normal);
				return normalize(float3(map(p+x)-map(p-x),map(p+y)-map(p-y),map(p+z)-map(p-z))); 
			}
			
			float3 lighting (float3 p)
			{
				float3 AmbientLight = float3 (0.1,0.1,0.1);
				float3 LightDirection = normalize(float3(_X,_Y,_Z));
				float3 LightColor = _Light.rgb;
				float3 NormalDirection = set_normal(p);
				return (max(dot(LightDirection, NormalDirection),0.0) * LightColor );
			}			
			
			float4 raymarch (float3 ro, float3 rd)
			{
				for (int i=0; i<128; i++)
				{
					float t = map(ro);
					if (t < 0.001 && ro.x>=0.0 && ro.x<=2.0 && ro.z>=0.0 && ro.z<=2.0) return float4 (lighting(ro),1.0);
					ro+=t*rd;
				}
				return float4(0.0,0.0,0.0,0.0);
			}
					
			SHADERDATA vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0) 
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (SHADERDATA ps) : COLOR
			{
				float2 resolution = float2(2048,2048); 
				float2 fragCoord = (ps.uv*resolution);
				float2 uv = (2.0*fragCoord-resolution)/resolution.y;
				float3 worldPosition = float3(1,2,1);
				float3 viewDirection = normalize(mul(rotationX(4.715),float3(uv,2.0)));			
				return raymarch(worldPosition,viewDirection) * tex2D(_MainTex,ps.uv);
			}
			ENDCG
		}
	}
}