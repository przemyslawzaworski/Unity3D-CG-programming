//Written by Przemyslaw Zaworski
//Shader shows configuration of using 24 textures per shader in single pass.

Shader "Texture Mapping"
{
	Properties
	{
		_Texture01 ("Texture 01", 2D) = "black" {}
		_Texture02 ("Texture 02", 2D) = "black" {}
		_Texture03 ("Texture 03", 2D) = "black" {}
		_Texture04 ("Texture 04", 2D) = "black" {}
		_Texture05 ("Texture 05", 2D) = "black" {}
		_Texture06 ("Texture 06", 2D) = "black" {}
		_Texture07 ("Texture 07", 2D) = "black" {}
		_Texture08 ("Texture 08", 2D) = "black" {}
		_Texture09 ("Texture 09", 2D) = "black" {}
		_Texture10 ("Texture 10", 2D) = "black" {}
		_Texture11 ("Texture 11", 2D) = "black" {}
		_Texture12 ("Texture 12", 2D) = "black" {}
		_Texture13 ("Texture 13", 2D) = "black" {}
		_Texture14 ("Texture 14", 2D) = "black" {}
		_Texture15 ("Texture 15", 2D) = "black" {}
		_Texture16 ("Texture 16", 2D) = "black" {}
		_Texture17 ("Texture 17", 2D) = "black" {}
		_Texture18 ("Texture 18", 2D) = "black" {}
		_Texture19 ("Texture 19", 2D) = "black" {}
		_Texture20 ("Texture 20", 2D) = "black" {}
		_Texture21 ("Texture 21", 2D) = "black" {}
		_Texture22 ("Texture 22", 2D) = "black" {}
		_Texture23 ("Texture 23", 2D) = "black" {}
		_Texture24 ("Texture 24", 2D) = "black" {}		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 5.0

			Texture2D _Texture01,_Texture02,_Texture03,_Texture04,_Texture05,_Texture06,_Texture07,_Texture08;
			Texture2D _Texture09,_Texture10,_Texture11,_Texture12,_Texture13,_Texture14,_Texture15,_Texture16;
			Texture2D _Texture17,_Texture18,_Texture19,_Texture20,_Texture21,_Texture22,_Texture23,_Texture24;

			SamplerState sampler_linear_repeat;

			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			structure vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps ) : SV_TARGET
			{
				float2 uv = ps.uv.xy;
				float2 scale = uv/float2(0.25,0.1666);
				if (uv.x<0.25 && uv.y<0.1666)
					return  _Texture01.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.25 && uv.y<0.3333)
					return  _Texture02.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.25 && uv.y<0.4999)
					return  _Texture03.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.25 && uv.y<0.6666)
					return  _Texture04.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.25 && uv.y<0.8333)
					return  _Texture05.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.25 && uv.y<=1.0)
					return  _Texture06.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.5 && uv.y<0.1666)
					return  _Texture07.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.5 && uv.y<0.3333)
					return  _Texture08.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.5 && uv.y<0.4999)
					return  _Texture09.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.5 && uv.y<0.6666)
					return  _Texture10.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.5 && uv.y<0.8333)
					return  _Texture11.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.5 && uv.y<=1.0)
					return  _Texture12.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.75 && uv.y<0.1666)
					return  _Texture13.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.75 && uv.y<0.3333)
					return  _Texture14.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<0.75 && uv.y<0.4999)
					return  _Texture15.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.75 && uv.y<0.6666)
					return  _Texture16.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.75 && uv.y<0.8333)
					return  _Texture17.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<0.75 && uv.y<=1.0)
					return  _Texture18.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<=1.0 && uv.y<0.1666)
					return  _Texture19.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<=1.0 && uv.y<0.3333)
					return  _Texture20.Sample(sampler_linear_repeat, scale);
				else
				if (uv.x<=1.0 && uv.y<0.4999)
					return  _Texture21.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<=1.0 && uv.y<0.6666)
					return  _Texture22.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<=1.0 && uv.y<0.8333)
					return  _Texture23.Sample(sampler_linear_repeat, scale); 
				else
				if (uv.x<=1.0 && uv.y<=1.0)
					return  _Texture24.Sample(sampler_linear_repeat, scale); 
				else
					return 1;
			}
			ENDCG
		}
	}
}