Shader "Hidden/TextureToBlocks"
{
	Subshader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			static const float3 _Vertices[36] = // vertices of single cube, in local space
			{
				{ 0.5, -0.5,  0.5}, { 0.5,  0.5,  0.5}, {-0.5,  0.5,  0.5},
				{ 0.5, -0.5,  0.5}, {-0.5,  0.5,  0.5}, {-0.5, -0.5,  0.5},
				{ 0.5,  0.5,  0.5}, { 0.5,  0.5, -0.5}, {-0.5,  0.5, -0.5},
				{ 0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5}, {-0.5,  0.5,  0.5},
				{ 0.5,  0.5, -0.5}, { 0.5, -0.5, -0.5}, {-0.5, -0.5, -0.5},
				{ 0.5,  0.5, -0.5}, {-0.5, -0.5, -0.5}, {-0.5,  0.5, -0.5},
				{ 0.5, -0.5, -0.5}, { 0.5, -0.5,  0.5}, {-0.5, -0.5,  0.5},
				{ 0.5, -0.5, -0.5}, {-0.5, -0.5,  0.5}, {-0.5, -0.5, -0.5},
				{-0.5, -0.5,  0.5}, {-0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5},
				{-0.5, -0.5,  0.5}, {-0.5,  0.5, -0.5}, {-0.5, -0.5, -0.5},
				{ 0.5, -0.5, -0.5}, { 0.5,  0.5, -0.5}, { 0.5,  0.5,  0.5},
				{ 0.5, -0.5, -0.5}, { 0.5,  0.5,  0.5}, { 0.5, -0.5,  0.5},
			};

			Texture3D<float4> _Texture3D;
			uint _Resolution;
			float _Scale;

			float4 VSMain (uint id : SV_VertexID, uint instance : SV_InstanceID, out float4 color : COLOR) : SV_POSITION
			{
				float3 uvw = float3(instance % _Resolution, (instance / _Resolution) % _Resolution, instance / (_Resolution * _Resolution));
				color = _Texture3D.Load(int4(uvw, 0));
				float scale = _Scale / float(_Resolution);
				float4 worldPos = float4(_Vertices[id] * scale + (uvw - 0.5 * _Resolution + 0.5) * scale, 1.0) ;
				return (color.a < 0.0) ? UnityObjectToClipPos(worldPos) : asfloat(0x7fc00000);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float4 color : COLOR) : SV_Target
			{
				return color;
			}
			ENDCG
		}
	}
}