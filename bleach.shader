Shader "Bleach Filter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _MainTex;
			static const float scale = 2.0;
			static const float4 c = float4(0.2124,0.7153,0.0722,0.0);

			float4 bleach(float4 p, float4 m, float4 s) 
			{
				float4 a = float4(1.0,1.0,1.0,1.0);
				float4 b = float4(2.0,2.0,2.0,2.0);
				float l = dot(m,c);
				float x = clamp((l - 0.45) * 10.0, 0.0, 1.0);
				float4 t = b * m * p;
				float4 w = a - (b * (a - m) * (a - p));
				float4 r = lerp(t, w, float4(x,x,x,x) );
				return lerp(m, r, s);
			}

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = ps.uv.xy;
				float4 p = tex2D(_MainTex,uv);
				float4 k = float4(dot(p,c),dot(p,c),dot(p,c),p.a);
				return bleach(k,p,float4(scale,scale,scale,1));
			}
			ENDCG
		}
	}
}