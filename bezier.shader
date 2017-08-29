//source: https://www.shadertoy.com/view/MsKGDV
Shader "Bezier"
{
	Properties
	{
		_color("Color", Color) = (1.0,1.0,1.0,1.0)
		_thickness("Thickness", Range(0.005,0.05)) = 0.01
		_Ax("A.x", Float) = -0.6
		_Ay("A.y", Float) =  0.0
		_Bx("B.x", Float) =  0.0
		_By("B.y", Float) =  0.5
		_Cx("C.x", Float) =  0.6
		_Cy("C.y", Float) =  0.0
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
			
			float4 _color;
			float _thickness,_Ax,_Ay,_Bx,_By,_Cx,_Cy;
			
			float det(float2 a,float2 b) 
			{
				float3 A = float3(a,0.0);
				float3 B = float3(b,0.0);
				float3 C = A.yzx*B.zxy-A.zxy*B.yzx;
				return C.z;
			}

			float Bezier(float2 b0,float2 b1,float2 b2)
			{
				float a = det(b0,b2),b = 2.*det(b1,b0),d = 2.*det(b2,b1);
				float f = b*d-a*a;
				float2 d21 = b2-b1,d10 = b1-b0,d20 = b2-b0;
				float2 gf = 2.*(b*d21+d*d10+a*d20);
				gf = float2(gf.y,-gf.x);
				float2 pp = -f*gf/dot(gf,gf);
				float2 d0p = b0-pp;
				float ap = det(d0p,d20),bp=2.*det(d10,d0p);
				float t = clamp((ap+bp)/(2.*a+b+d),0.,1.);
				float2 vi = lerp(lerp(b0,b1,t),lerp(b1,b2,t),t);
				return length(vi);
			}
			
			custom_type vertex_shader (float4 vertex : POSITION, float2 uv : TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 u = float2(2.0*ps.uv.xy-1.0);
				float2 A = float2(_Ax,_Ay),B = float2(_Bx,_By),C = float2(_Cx,_Cy);
				return lerp (_color,float4(0,0,0,1),step(_thickness,Bezier(A-u,B-u,C-u)));
			}
			ENDCG
		}
	}
}