//written by Przemyslaw Zaworski
//https://github.com/przemyslawzaworski

Shader "Skybox Blur" 
{
	Properties 
	{
		_Cube ("Environment Map", Cube) = "white" {}
		_radius ("Blur Radius", Range (0.01,2.0)) = 0.5
	}
	SubShader 
	{
		Tags { "Queue"="Background"  }
		Pass 
		{
			ZWrite Off 
			Cull Off
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			TextureCube _Cube;
			SamplerState sampler_Cube;
			float _radius;

			struct structure
			{
				float4 vertex:SV_POSITION;
				float3 uv : TEXCOORD0;
			};

			float3 blur(float3 uv,float radius)
			{
				float w, h;
				_Cube.GetDimensions(w, h);
				float2x2 m = float2x2(-0.736717,0.6762,-0.6762,-0.736717);
				float3 total = float3(0.0,0.0,0.0);
				float2 s = float2(1.0/w,1.0/h);
				float2 texel = float2(0.002*s.x/s.y,0.002);
				float2 angle = float2(0.0,radius);
				radius = 1.0;
				for (int j=0;j<80;j++)
				{
					radius += (1.0/radius); 
					angle = mul(angle,m);
					float3 color = _Cube.Sample(sampler_Cube,uv+float3(texel*(radius-1.0)*angle,0.0)).rgb;
					total += color;
				}
				return total/80.0;
			}
			
			void vertex_shader(float4 vertex:POSITION,float3 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target)
			{
				fragColor = float4(blur(ps.uv,_radius),1.0);
			}
			
			ENDCG 
		}
	}
}