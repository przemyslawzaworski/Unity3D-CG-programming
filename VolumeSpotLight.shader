Shader "VolumeSpotLight"
{
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			
			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;
			float4x4 _CameraInvViewMatrix;
			float4x4 _FrustumCornersES;
			float4 _CameraWS;

			bool cone(float3 org, float3 dir, out float near, out float far, float d)
			{
				org.x += 0.5;
				float s = 0.5;
				org.x *= s;
				dir.x *= s;
				float a = dir.y * dir.y + dir.z * dir.z - dir.x * dir.x;
				float b = org.y * dir.y + org.z * dir.z - org.x * dir.x;
				float c = org.y * org.y + org.z * org.z - org.x * org.x;	
				float cap = (s - org.x) / dir.x;	
				if( a == 0.0 )
				{
					near = -0.5 * c/b;
					float x = org.x + near * dir.x;
					if( x < 0.0 || x > s ) return false; 
					far = cap;
					float temp = min(far, near); 
					far = max(far, near);
					near = temp;
					return far > 0.0;
				}
				float delta = b * b - a * c;
				if( delta < 0.0 ) return false;
				float deltasqrt = sqrt(delta);
				float arcp = 1.0 / a;
				near = (-b - deltasqrt) * arcp;
				far = (-b + deltasqrt) * arcp;
				float temp = min(far, near);
				far = max(far, near);
				near = temp;
				float xnear = org.x + near * dir.x;
				float xfar = org.x + far * dir.x;	
				if( xnear < 0.0 )
				{
					if( xfar < 0.0 || xfar > s ) return false;		
					near = far;
					far = cap;
				}
				else if( xnear > s )
				{
					if( xfar < 0.0 || xfar > s ) return false;		
					near = cap;
				}
				else if( xfar < 0.0 )
				{
					far = near;
					near = cap;
				}
				else if( xfar > s )
				{
					far = cap;
				}		
				if (far>d) return false;
				return far > 0.0;
			}		
						
			void VSMain (inout float4 vertex : POSITION, inout float2 uv : TEXCOORD0, out float3 ray:TEXCOORD1)
			{			
				half index = vertex.z;
				vertex.z = 0.1;				
				vertex = UnityObjectToClipPos(vertex);
				ray = _FrustumCornersES[(int)index].xyz;
				ray /= abs(ray.z);
				ray = mul(_CameraInvViewMatrix, ray);
			}
			
			float4 PSMain (float4 vertex : POSITION, float2 uv : TEXCOORD0, float3 ray:TEXCOORD1) : SV_Target
			{		
				float far=0.0, near=0.0;
				float depth = 1.0 / (_ZBufferParams.z * tex2D(_CameraDepthTexture,uv).r + _ZBufferParams.w) * length(ray);   
				float4 color = tex2D(_MainTex,uv);			
				if (cone (_CameraWS, normalize(ray), near, far, depth))
				{
					float k = far - max(near, 0.0);
					color += float4(k,k,0.9*k,k);
				}			
				return color;
			}
			ENDCG
		}
	}
}