/* 	Include following CS script from https://github.com/przemyslawzaworski/Unity3D-C-programming/blob/master/fullscreen.cs
	to Main Camera, then assign material with shader. 
	Set texture into properties slot. After play, you can see that subtexture coordinates fit the center of screen, even with 
	screen resize. 
	DirectX 9 variant.
	
	Copyright 2017 Przemyslaw Zaworski

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
	to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
	IN THE SOFTWARE.
	
*/

Shader "Shader GUI - variant 01"
{
	Properties
	{
		_texture("Texture", 2D) = "black" {}
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			sampler2D _texture;
			float4 _texture_TexelSize;
			
			float4 vertex_shader (float4 vertex : POSITION) : POSITION
			{
				return  UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (float2 F:VPOS) : COLOR
			{			
				float2 subtexture = float2(_texture_TexelSize.z,_texture_TexelSize.w);
				float2 center = _ScreenParams.xy *0.5; 				
				float a = center.x-subtexture.x*0.5;
				float b = center.y-subtexture.y*0.5;
				float c = center.x+subtexture.x*0.5;
				float d = center.y+subtexture.y*0.5;
				float4 rect = float4( a,b,c,d); //set borders
				float2 u =float2(F/subtexture +float2(-(_ScreenParams.x/(subtexture.x*2.0))-1.0,-(_ScreenParams.y/(subtexture.y*2.0)))-0.5 );
				u.y=1.0-u.y;
				return
				(F.x>=rect.x && F.x<=rect.z && F.y>=rect.y && F.y<=rect.w) ? tex2D(_texture,u):
				(F.x<rect.x) ? float4(1,0,0,1):
				(F.x>rect.z) ? float4(1,1,0,1):
				(F.y<rect.y) ? float4(0,0,1,1):float4(0,0.5,0,1);
			}
			ENDCG
		}
	}
}