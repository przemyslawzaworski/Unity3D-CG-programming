//reference: https://www.gamedev.net/articles/programming/graphics/advanced-terrain-texture-splatting-r3287/
//Shader written by Przemyslaw Zaworski
//Color textures (A-C) require depth maps - "Alpha from Grayscale"

Shader "Unlit Splat Mapping"
{
	Properties
	{
		_terrain_width ("Terrain width", Float) = 500.0
		_terrain_length ("Terrain length", Float) = 500.0
		_textureA ("Texture A", 2D) = "black" {}
		_textureB ("Texture B", 2D) = "black" {}
		_textureC ("Texture C", 2D) = "black" {}
		_opacity_map ("Opacity map (RGB)", 2D) = "black" {}
		_depth ("Depth", Range (0.05,1.0)) = 0.2
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _textureA,_textureB,_textureC,_opacity_map;
			float4 _textureA_ST,_textureB_ST,_textureC_ST;
			float _terrain_width, _terrain_length, _depth;
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
				float2 uv3 : TEXCOORD3;
			};

			float3 blend(float4 texture1, float a1, float4 texture2, float a2, float4 texture3, float a3)
			{
				float ma = max(max(texture1.a + a1, texture2.a + a2),texture3.a + a3) - _depth;
				float b1 = max(texture1.a + a1 - ma, 0);
				float b2 = max(texture2.a + a2 - ma, 0);
				float b3 = max(texture3.a + a3 - ma, 0);
				return (texture1.rgb * b1 + texture2.rgb * b2 + texture3.rgb * b3) / (b1 + b2 + b3);
			}
			
			structure vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				float2 t = float2(_terrain_width,_terrain_length);
				vs.uv0=uv;
				vs.uv1=uv/_textureA_ST.xy*t;
				vs.uv2=uv/_textureB_ST.xy*t;
				vs.uv3=uv/_textureC_ST.xy*t;		
				return vs;
			}

			float4 pixel_shader (structure ps) : SV_TARGET
			{
				float m1 = tex2D(_opacity_map,ps.uv0).r;
				float m2 = tex2D(_opacity_map,ps.uv0).g;
				float m3 = tex2D(_opacity_map,ps.uv0).b;
				float3 color = blend(tex2D(_textureA,ps.uv1),m1,tex2D(_textureB,ps.uv2),m2,tex2D(_textureC,ps.uv3),m3);
				return float4(color,1.0);
			}

			ENDCG
		}
	}
}