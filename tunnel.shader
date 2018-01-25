Shader "Tunnel"
{
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
			
			float h(float2 n) 
{ 
	return frac(sin(dot(fmod(n, 9.), float2(12.9898, 4.1414))) * 43758.5453);
}

float n(float2 p)
{
	float2 i = floor(p), u = frac(p);
	u = u*u*(3.-2.*u);
	float r = lerp(
		lerp(h(i),h(i+float2(1,0)),u.x),
		lerp(h(i+float2(0,1)),h(i+float2(1,1)),u.x),u.y);
	return r*r;
}

float t(float2 u) 
{ 
    float r = length( u );   
    u = float2( 1./r + (_Time.g*2.), atan2( u.y, u.x )/3.1415927 );  
    return n( 9.*u )*r;
}
			
			
			
			structure vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				structure vs;
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (structure ps) : SV_TARGET
			{
				float2 u = float2(2.0*ps.uv.xy-1.0);
				    u.y+=sin(_Time.g)*n(u);
    u.x-=cos(_Time.g);
	return float4(t(u),0,0,1);	
			}
			ENDCG
		}
	}
}