// Conservative Rasterization with Geometry Shaders: https://action-io.com/rd/conservative-rasterization/ 
// Translated from GLSL to HLSL by Przemyslaw Zaworski

Shader "Bake Texture"
{
	SubShader
	{
		Pass
		{
			ZWrite On
			Cull Off
			HLSLPROGRAM
			#pragma vertex VSMain
			#pragma geometry GSMain
			#pragma fragment PSMain

			float _Dilation;
			int _TextureSize;
			int _RenderMode;

			struct Interpolators
			{
				float4 vertex : SV_Position;
				float2 uv : TEXCOORD0;
				float4 color : NORMAL;
			};

			Interpolators VSMain(float4 vertex:POSITION, float2 uv:TEXCOORD0, float4 color : NORMAL)
			{
				Interpolators IN;
				float2 texcoord = uv.xy;
				texcoord.y = (_RenderMode == 0) ? 1.0 - texcoord.y : texcoord.y;
				texcoord = texcoord * 2.0 - 1.0;
				IN.uv = uv;
				IN.vertex = float4(texcoord, 0.0, 1.0);
				IN.color = color;
				return IN;
			}

			void Emit(float4 position, float2 uv, float4 color, inout TriangleStream<Interpolators> stream, float depth)
			{
				Interpolators IN;
				depth = (_RenderMode == 0) ? depth : -1.0 * depth;
				IN.vertex = float4(position.xy, depth, position.w);
				IN.uv = uv;
				IN.color = color;
				stream.Append(IN);
			}

			[maxvertexcount(21)] 
			void GSMain(triangle Interpolators input[3], inout TriangleStream<Interpolators> stream)
			{
				float pixel = (1.0 / (float)_TextureSize) * _Dilation;
				float4 vertices[3];
				for (int i = 0; i < 3; i++) 
				{
					int i0 = i, i1 = (i + 1) % 3u, i2 = (i + 2) % 3u;
					float4 lp0 = input[i0].vertex;
					float4 lp1 = input[i1].vertex;
					float4 lp2 = input[i2].vertex;
					float2 v0 = normalize(lp0.xy - lp1.xy);
					float2 v1 = normalize(lp2.xy - lp1.xy);
					float2 mixed = -normalize((v0 + v1)/ 2.0);
					float angle = atan2(v0.y, v0.x) - atan2(mixed.y, mixed.x);
					float vlength = abs(pixel / sin(angle));
					float2 offs = mixed * float2(vlength, vlength);
					vertices[i1] = float4(lp1.xy + offs, 0, 1);
				}
				Emit(input[0].vertex, input[0].uv, input[0].color, stream, 0.0007);
				Emit(input[1].vertex, input[1].uv, input[1].color, stream, 0.0007);
				Emit(input[2].vertex, input[2].uv, input[2].color, stream, 0.0007);
				stream.RestartStrip();
				Emit(input[1].vertex, input[1].uv, input[1].color, stream, 0.0006);
				Emit(vertices[2], input[2].uv, input[2].color, stream, 0.0006);
				Emit(input[2].vertex, input[2].uv, input[2].color, stream, 0.0006);
				stream.RestartStrip();
				Emit(input[2].vertex, input[2].uv, input[2].color, stream, 0.0005);
				Emit(vertices[2], input[2].uv, input[2].color, stream, 0.0005);
				Emit(input[0].vertex, input[0].uv, input[0].color, stream, 0.0005);
				stream.RestartStrip();
				Emit(input[0].vertex, input[0].uv, input[0].color, stream, 0.0004);
				Emit(vertices[2], input[2].uv, input[2].color, stream, 0.0004);
				Emit(vertices[0], input[0].uv, input[0].color, stream, 0.0004);
				stream.RestartStrip();
				Emit(input[0].vertex, input[0].uv, input[0].color, stream, 0.0003);
				Emit(vertices[0], input[0].uv, input[0].color, stream, 0.0003);
				Emit(input[1].vertex, input[1].uv, input[1].color, stream, 0.0003);
				stream.RestartStrip();
				Emit(input[1].vertex, input[1].uv, input[1].color, stream, 0.0002);
				Emit(vertices[0], input[0].uv, input[0].color, stream, 0.0002);
				Emit(vertices[1], input[1].uv, input[1].color, stream, 0.0002);
				stream.RestartStrip();
				Emit(input[1].vertex, input[1].uv, input[1].color, stream, 0.0001);
				Emit(vertices[1], input[1].uv, input[1].color, stream, 0.0001);
				Emit(vertices[2], input[2].uv, input[2].color, stream, 0.0001);
				stream.RestartStrip();
			}

			float4 PSMain (Interpolators IN) : SV_TARGET
			{
				return float4(IN.color.rgb, 1.0);
			}
			ENDHLSL
		}
	}
}