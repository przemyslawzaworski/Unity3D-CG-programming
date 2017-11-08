Shader "Orthogonal sphere"
{
	Properties
	{
		_lightcolor("Light Color", Color) = (0.0,1.0,0.0,1.0) 
		_lightposition("Light Position", Vector) = (8.0,0.0,10.0,1.0)
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 2.0

			float4 _lightcolor, _lightposition;
			
			struct type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
	
			float3 sphere (float2 p, float s)
			{
				float z = sqrt(abs(s*s-dot(p,p)));
				return float3(p,z);
			}

			float3 map (float2 p)
			{
				return sphere(p,0.5);
			}

			float4 lighting (float2 p)
			{
				float3 AmbientLight = float3 (0.0,0.0,0.0);
				float3 LightDirection = normalize(_lightposition);
				float3 NormalDirection = normalize(map(p));
				float3 LightColor = _lightcolor.xyz;
				float3 DiffuseColor = max(dot(NormalDirection,LightDirection),0.0)*LightColor+AmbientLight;
				return float4(DiffuseColor,1.0); 
			}

			type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (type ps) : SV_TARGET
			{
				float2 uv = 2.0*ps.uv.xy-1.0;
				return lighting(uv);	
			}
			ENDCG
		}
	}
}