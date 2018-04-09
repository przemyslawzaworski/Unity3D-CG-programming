Shader "Isolines 2"
{
	Properties
	{
		_BaseTexture ("Base Texture", 2D) = "black" {}	
		_thickness("Contour Thickness",Range (0.1,2.0)) = 1.0	
		_density("Contour Density",Range (1.0,50.0)) = 10.0					
	}
	Subshader
	{
		Pass
		{	
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct structure
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _BaseTexture;
			float _thickness, _density;
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : COLOR
			{  
				float3 color = tex2Dgrad(_BaseTexture,ps.uv,ddx(ps.uv.x),ddy(ps.uv.y)).rgb;					
				float3 f  = abs(frac(color*_density)-0.5);
				float3 df = fwidth(color*_density);
				float a = max(0.0,_thickness-1.0);
				float b = max(1.0,_thickness);
				float3 g = clamp((f-df*a)/(df*(b-a)),max(0.0,1.0-_thickness),1.0);
				float c = g.x * g.y * g.z;
				return float4(c, c, c, 1.0);
			}
			ENDCG
		}
	}
}