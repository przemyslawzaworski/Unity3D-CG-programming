/*
	Surface shader uses 24 textures and blends them, with 1 texture sampler.
	To enable anisotropic filtering, set "aniso level" to 16 in import settings
	for texture assigned to first slot (Texture 01). 
	To get correct values from uv_texcoord, it seems we have to pass them also to
	the dummy function and use into one of render target (for example o.Normal, o.Smoothness etc).
	To see a difference, replace:
	o.Smoothness = ReturnZero(i.uv_texcoord);
	with 
	o.Smoothness = 0.5;
*/

Shader "MultiTexturing"
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
		[HideInInspector] _texcoord( "", 2D ) = "black" {}
	}

	Subshader
	{
		CGPROGRAM
		#pragma target 5.0
		#pragma surface SurfaceShader Standard fullforwardshadows addshadow 

		#ifdef SHADER_API_D3D11
			Texture2D _Texture01,_Texture02,_Texture03,_Texture04,_Texture05,_Texture06,_Texture07,_Texture08;
			Texture2D _Texture09,_Texture10,_Texture11,_Texture12,_Texture13,_Texture14,_Texture15,_Texture16;
			Texture2D _Texture17,_Texture18,_Texture19,_Texture20,_Texture21,_Texture22,_Texture23,_Texture24;
			SamplerState sampler_Texture01;
		#endif

		struct Input
		{
			float2 uv_texcoord;
		};

		float ReturnZero(float2 p)
		{
			return (p.x == 171076.61627) ? 1.0 : 0.0;
		}

		void SurfaceShader (Input i, inout SurfaceOutputStandard o) 
		{
			float4 albedo = 0;
			#ifdef SHADER_API_D3D11
				albedo += _Texture01.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture02.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture03.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture04.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture05.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture06.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture07.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture08.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture09.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture10.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture11.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture12.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture13.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture14.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture15.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture16.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture17.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture18.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture19.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture20.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture21.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture22.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture23.Sample(sampler_Texture01, i.uv_texcoord);
				albedo += _Texture24.Sample(sampler_Texture01, i.uv_texcoord);
				albedo = albedo / 24.0;
			#endif
			o.Albedo = albedo; 
			o.Normal = float3(0,0,1);  
			o.Metallic = 0.0; 
			o.Smoothness = ReturnZero(i.uv_texcoord); 
		}

		ENDCG
	}
}