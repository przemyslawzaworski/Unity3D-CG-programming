Shader "Planet"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			Texture2D<float4> _CameraDepthTexture, _MainTex;
			float4x4 _CameraToWorldMatrix, _FrustumCorners;
			SamplerState _PointClamp;

			// ro = ray origin; rd = ray direction; c = sphere center; r = sphere radius; 
			// returns the distance to the closest intersection;
			float Sphere (float3 ro, float3 rd, float3 c, float r)
			{
				float3 oc = ro - c;
				float b = dot(oc, rd);
				float h = b * b - (dot(oc, oc) - r * r);
				if(h < 0.0) return -1.0; 
				return -b - sqrt(h);
			}

			float3 CartesianToSpherical (float3 p)
			{
				float radius = sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
				float theta = acos(p.y / radius);
				float phi = atan2(p.z, p.x);
				return float3(radius, theta, phi);
			}

			float3 Wireframe(float2 p)
			{
				float thickness = 0.1;
				float scale = 5.0;
				p = p * scale * 3.14159265359;
				float2 gradient = abs(frac(p - 0.5) - 0.5) / fwidth(p);
				float grid = min(gradient.x, gradient.y) * thickness;
				return (float3) grid;
			}

			float4 Lighting(float3 worldPos)
			{
				float3 coords = CartesianToSpherical(worldPos);
				float2 surface = float2(coords.y, coords.z);
				float wireframe = Wireframe(surface);
				return float4((float3) wireframe, 1.0);
			}

			float4 Raycasting (float3 ro, float3 rd, float depth)
			{
				float intersection = Sphere(ro, rd, float3(0,0,0), 5.0);
				float3 hitPoint = ro + rd * intersection;
				bool isVisible = intersection > 0.0 && intersection < depth;
				return isVisible ? float4(1,0,0,1) * Lighting(hitPoint) : float4(0,0,0,0);
			}

			float4 VSMain (float3 vertex:POSITION, inout float3 uv:TEXCOORD0, out float3 ray:TEXCOORD1) : SV_POSITION
			{
				int index = (int)uv.z;
				ray = _FrustumCorners[index].xyz;
				ray = ray / abs(ray.z);
				ray = mul(_CameraToWorldMatrix, ray);
				return UnityObjectToClipPos(float4(vertex, 1.0));
			}

			float4 PSMain (float4 vertex:SV_POSITION, float3 uv:TEXCOORD0, float3 ray:TEXCOORD1) : SV_Target
			{
				float3 position = _WorldSpaceCameraPos;
				float3 direction = normalize(ray);
				float sample = _CameraDepthTexture.Sample(_PointClamp, uv).r;
				float depth = 1.0 / (_ZBufferParams.z * sample + _ZBufferParams.w) * length(ray);
				float4 color = _MainTex.Sample(_PointClamp, uv);
				float4 volume = Raycasting(position, direction, depth);
				return lerp(color, volume, volume.w);
			}
			ENDCG
		}
	}
}