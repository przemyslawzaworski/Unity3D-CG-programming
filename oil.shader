//reference: https://www.reddit.com/r/Unity3D/comments/5epe0e/unity_shader_oil_painting_effect_kuwahara_filter/

Shader "Oil painting"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Radius ("Range", Range(0, 10)) = 5
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			int _Radius;

			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};
            
			structure vertex_shader(float4 vertex:POSITION,float2 uv:TEXCOORD0) 
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv;
				return vs;
			}

			struct region 
			{
				int x1, y1, x2, y2;
			};

			float4 pixel_shader(structure ps) : SV_Target
			{
				float2 uv = ps.uv;
				float n = float((_Radius + 1) * (_Radius + 1));
				float4 color = tex2D(_MainTex, uv);
				float3 m[4];
				float3 s[4];
				for (int kk = 0; kk < 4; ++kk) 
				{
					m[kk] = float3(0, 0, 0);
					s[kk] = float3(0, 0, 0);
				}
				region R[4] = 
				{
					{-_Radius, -_Radius,       0,       0},
					{       0, -_Radius, _Radius,       0},
					{       0,        0, _Radius, _Radius},
					{-_Radius,        0,       0, _Radius}
				};
				for (int k = 0; k < 4; ++k) 
				{
					for (int j = R[k].y1; j <= R[k].y2; ++j) 
					{
						for (int i = R[k].x1; i <= R[k].x2; ++i) 
						{
							float3 c = tex2Dlod(_MainTex,float4(uv+(float2(i*_MainTex_TexelSize.x,j*_MainTex_TexelSize.y)),0,0)).rgb;
							m[k] += c;
							s[k] += c * c;
						}
					}
				}
				float min = 1e+2;
				float s2;
				for (k = 0; k < 4; ++k) 
				{
					m[k] /= n;
					s[k] = abs(s[k] / n - m[k] * m[k]);
					s2 = s[k].r + s[k].g + s[k].b;
					if (s2 < min) 
					{
						min = s2;
						color.rgb = m[k].rgb;
					}
				}
				return color;
			}
			ENDCG
		}
	}
}