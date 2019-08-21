Shader "Draw Cubes"
{
	Subshader
	{	
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Pass
		{
			Cull Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			float3 hash(uint p)
			{
				p = 1103515245U*((p >> 1U)^(p));
				uint h32 = 1103515245U*((p)^(p>>3U));
				uint n = h32^(h32 >> 16);
				uint3 rz = uint3(n, n*16807U, n*48271U);
				return float3((rz >> 1) & uint3(0x7fffffffU,0x7fffffffU,0x7fffffffU))/float(0x7fffffff);
			}
			
			void GenerateCube (inout uint id, inout float3 normal, inout float3 position, inout float instance)
			{
				float PI = 3.14159265;
				float q = floor((id-36.0*floor(id/36.0))/6.0); 
				float s = q-3.0*floor(q/3.0); 
				float inv = -2.0*step(2.5,q)+1.0;
				float f = id-6.0*floor(id/6.0);
				float t = f-floor(f/3.0); 
				float a = (t-6.0*floor(t/6.0))*PI*0.5+PI*0.25;
				float3 p = float3(cos(a),0.707106781,sin(a))*inv;
				float x = (s-2.0*floor(s/2.0))*PI*0.5; 
				float4x4 mat = float4x4(1,0,0,0,0,cos(x),sin(x),0,0,-sin(x),cos(x),0,0,0,0,1);
				float z = step(2.0,s)*PI*0.5;
				mat = mul(mat,float4x4(cos(z),-sin(z),0,0,sin(z),cos(z),0,0,0,0,1,0,0,0,0,1));
				position = (mul(float4(p,1.0),mat)).xyz;
				normal = (mul(float4(float3(0,1,0)*inv,0),mat)).xyz;
				instance = floor(id/36.0);
			}

			float4 VSMain (uint id:SV_VertexID, out float3 normal:TEXCOORD0, out float3 position:TEXCOORD1, out float instance:TEXCOORD2) : SV_POSITION
			{
				GenerateCube (id, normal, position, instance);
				float3 random = hash(uint(instance))*256;
				position.xz += random.xz;
				position.y += (sin(_Time.g+random.y)*0.5+0.5)*256;
				return UnityObjectToClipPos(float4(position,1.0));
			}

			float4 PSMain (float4 vertex:SV_POSITION, float3 normal:TEXCOORD0, float3 position:TEXCOORD1, float instance:TEXCOORD2) : SV_Target
			{
				float3 uv = position/256.0;
				return float4(lerp(float3(1,1,1),float3(0,0,1),uv.y),pow(uv.y,4.0));
			}
			ENDCG
		}
		
	}
}