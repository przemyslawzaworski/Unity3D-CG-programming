/* "Shadow Volume" technique - the simplest example. Works for 3D Object / Sphere.
It extrudes mesh vertices which are not lit by Directional Light (where angle is below zero).
It is done twice, in first and second pass. First pass renders mesh with backface culling.
Second pass renders mesh with frontface culling. With proper stencil buffer setup, we get a difference
between volume shape from both cull modes. It is a shadow ! 
When vertices are displaced with vertex shader, but base object is not in camera frustum, extruded vertices will be invisible.
It is possible to edit mesh bounds as workaround:
this.GetComponent<MeshFilter>().sharedMesh.bounds = new Bounds(new Vector3(0f, 0f, 0f), new Vector3(500f, 500f, 500f)); */

Shader "Shadow Volume For Sphere Only"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Overlay"}
		ZWrite Off
		Pass
		{
			Cull Back
			ZTest Greater
			ColorMask 0
 
			Stencil 
			{
				Ref 1
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			void VSMain (inout float4 vertex : POSITION, in float3 normal : NORMAL)
			{
				float4 worldPos = mul(unity_ObjectToWorld, vertex);
				float3 normalDir = normalize(mul(unity_ObjectToWorld, float4(normal, 0.0))).xyz;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float angle = dot(lightDir, normalDir);
				if (angle < 0.0) worldPos.xyz = worldPos.xyz - lightDir * 1000.0f;
				vertex = mul(UNITY_MATRIX_VP, worldPos);
			}

			void PSMain (float4 vertex : POSITION, out float4 fragColor : SV_Target) 
			{
				fragColor = 0.1;
			}
			ENDCG
		}
		

		Pass
		{
			Cull Front
			ZTest Greater
 
			Stencil 
			{
				Ref 1
				Comp NotEqual
			}

			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			void VSMain (inout float4 vertex : POSITION, in float3 normal : NORMAL)
			{
				float4 worldPos = mul(unity_ObjectToWorld, vertex);
				float3 normalDir = normalize(mul(unity_ObjectToWorld, float4(normal, 0.0))).xyz;
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float angle = dot(lightDir, normalDir);
				if (angle < 0.0) worldPos.xyz = worldPos.xyz - lightDir * 1000.0f;
				vertex = mul(UNITY_MATRIX_VP, worldPos);
			}

			void PSMain (float4 vertex : POSITION, out float4 fragColor : SV_Target) 
			{
				fragColor = 0.1;
			}
			ENDCG
		}

		Pass
		{
			
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain

			void VSMain (inout float4 vertex : POSITION, inout float3 normal : NORMAL)
			{
				normal = normalize(mul(unity_ObjectToWorld, float4(normal, 0.0))).xyz;
				vertex = UnityObjectToClipPos(vertex);
			}

			void PSMain (float4 vertex : POSITION, float3 normal : NORMAL, out float4 fragColor : SV_Target) 
			{
				float angle = dot(normalize(_WorldSpaceLightPos0.xyz), normal);
				fragColor = float4(angle.xxx, 1.0);
			}
			ENDCG
		}
	}
}