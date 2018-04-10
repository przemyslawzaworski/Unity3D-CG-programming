// https://github.com/przemyslawzaworski

Shader "Subtexture"
{
	Properties
	{
		_Texture ("Main Texture", 2D) = "black" {}
		_Subtexture ("Sub Texture", 2D) = "black" {}	
		[Toggle] _rotation("Self Rotation", Float) = 0	
		_TextureRes("Main Texture Resolution", Int) = 512
		_SubtextureRes("Sub Texture Resolution", Int) = 128
		_SubtexturePosX("Sub Texture Position X", Int) = 128
		_SubtexturePosY("Sub Texture Position Y", Int) = 128			
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
				
			sampler2D _Texture, _Subtexture;
			float _rotation;
			int _TextureRes, _SubtextureRes, _SubtexturePosX, _SubtexturePosY;
			
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
				float2 center = float2 (_SubtexturePosX,_SubtexturePosY);   //subtexture center position 
				float2 texture_resolution = float2(_TextureRes,_TextureRes);
				float2 subtexture_resolution = float2(_SubtextureRes,_SubtextureRes);			
				float2 pixel = ps.uv*texture_resolution;   //fragment coordinates
				float s = sin(_Time.g), c = cos(_Time.g);
				float2 uv = (pixel-center.xy+subtexture_resolution*0.5)/subtexture_resolution-0.5;
				float2 n = float2 (c*uv.x-s*uv.y,s*uv.x+c*uv.y)+0.5; 
				if (_rotation==0.0) n=uv+0.5;
				if (n.x<=1.0 && n.y<=1.0 && n.x>=0.0 && n.y>=0.0) 
					return tex2D(_Subtexture,n); 
				else 
					return tex2D(_Texture,ps.uv);
			}

			ENDCG
		}
	}
}