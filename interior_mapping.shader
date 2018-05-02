//reference: http://www.habrador.com/tutorials/shaders/2-interior-mapping/

Shader "Interior Mapping"
{
	Properties 
	{
		_FloorTexture ("Floor texture", 2D) = "black" {}
		_RoofTexture ("Roof texture", 2D) = "black" {}
		_Wall01Texture ("Wall 01 texture", 2D) = "black" {}
		_Wall02Texture ("Wall 02 texture", 2D) = "black" {}
		_GridTexture ("Grid texture", 2D) = "black" {}		
		distanceBetweenFloors ("Distance Between Floors", Range (0.1, 2.0)) = 0.25
		distanceBetweenWalls ("Distance Between Walls", Range (0.1, 2.0)) = 0.25		
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			sampler2D _FloorTexture,_RoofTexture,_Wall01Texture,_Wall02Texture,_GridTexture;
			float4 _FloorTexture_ST,_RoofTexture_ST,_Wall01Texture_ST,_Wall02Texture_ST;
			float distanceBetweenFloors ;
			float distanceBetweenWalls ;
			static float3 upVec = float3(0, 1, 0);
			static float3 rightVec = float3(1, 0, 0);
			static float3 forwardVec = float3(0, 0, 1);
			
			struct SHADERDATA
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 objectViewDir : TEXCOORD1;
				float3 objectPos : TEXCOORD2;
			};
		
			SHADERDATA vertex_shader (float4 vertex:POSITION,float2 uv:TEXCOORD0)
			{
				SHADERDATA vs;
				vs.vertex = UnityObjectToClipPos (vertex);
				vs.uv = uv;
				float3 objectCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;					
				vs.objectViewDir = vertex - objectCameraPos;
				vs.objectPos = vertex;
				return vs;
			}

			float4 checkIfCloser(float3 rayDir, float3 rayStartPos, float3 planePos, float3 planeNormal, float4 color, float4 colorAndDist)
			{
				float t = dot(planePos - rayStartPos, planeNormal) / dot(planeNormal, rayDir);
				if (t < colorAndDist.w)
				{
					colorAndDist.w = t;
					colorAndDist.rgb = color;
				}
				return colorAndDist;
			}

			float4 pixel_shader (SHADERDATA ps) : SV_TARGET
			{
				float4 _ColorFloor = tex2D(_FloorTexture,ps.uv*_FloorTexture_ST.xy+_FloorTexture_ST.zw);
				float4 _ColorRoof = tex2D(_RoofTexture,ps.uv*_RoofTexture_ST.xy+_RoofTexture_ST.zw);
				float4 _ColorWall = tex2D(_Wall01Texture,ps.uv*_Wall01Texture_ST.xy+_Wall01Texture_ST.zw);
				float4 _ColorWall2 = tex2D(_Wall02Texture,ps.uv*_Wall02Texture_ST.xy+_Wall02Texture_ST.zw);
				float3 rayDir = normalize(ps.objectViewDir);
				float3 rayStartPos = ps.objectPos;
				rayStartPos += rayDir * 0.0001;
				float4 colorAndDist = float4(float3(1,1,1), 100000000.0);
				if (dot(upVec, rayDir) > 0)
				{
					float3 wallPos = (ceil(rayStartPos.y / distanceBetweenFloors) * distanceBetweenFloors) * upVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec, _ColorRoof, colorAndDist);
				}
				else
				{
					float3 wallPos = ((ceil(rayStartPos.y / distanceBetweenFloors) - 1.0) * distanceBetweenFloors) * upVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, _ColorFloor, colorAndDist);
				}
				if (dot(rightVec, rayDir) > 0)
				{
					float3 wallPos = (ceil(rayStartPos.x / distanceBetweenWalls) * distanceBetweenWalls) * rightVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec, _ColorWall, colorAndDist);
				}
				else
				{
					float3 wallPos = ((ceil(rayStartPos.x / distanceBetweenWalls) - 1.0) * distanceBetweenWalls) * rightVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec * -1, _ColorWall, colorAndDist);
				}
				if (dot(forwardVec, rayDir) > 0)
				{
					float3 wallPos = (ceil(rayStartPos.z / distanceBetweenWalls) * distanceBetweenWalls) * forwardVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec, _ColorWall2, colorAndDist);
				}
				else
				{
					float3 wallPos = ((ceil(rayStartPos.z / distanceBetweenWalls) - 1.0) * distanceBetweenWalls) * forwardVec;
					colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec * -1, _ColorWall2, colorAndDist);
				}
				float4 externalcolor = tex2D(_GridTexture,ps.uv);
				return lerp(float4(colorAndDist.rgb,1.0),externalcolor.rgba,externalcolor.a); 
			}
			ENDCG
		}
		Pass
		{		
			Tags{ "LightMode" = "ShadowCaster" }		
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			float4 vertex_shader (float4 vertex:POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);								
			}

			float4 pixel_shader (void) : COLOR
			{
				return 0;
			}
			ENDCG
		}		
	}
}