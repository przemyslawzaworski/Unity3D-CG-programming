//652 chars
//Apply material with shader to quad.
//Compiled in Unity 2018.1.0f2
//Author: Przemyslaw Zaworski

Shader "I"
{
	Subshader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex V
			#pragma fragment P

			#define l lerp
			
			float f(float3 x) 
			{
				float3 p = floor(x),f = smoothstep(0,1,frac(x)),n = {1,0,0};
				#define h(m) frac(sin(dot(m,float3(1,13,57)))*1e5)
				return l(l(l(h(p),h(p+n.xyy),f.x),l(h(p+n.yxy),h(p+n.xxy),f.x),f.y),l(l(h(p+n.yyx),h(p+n.xyx),f.x),l(h(p+n.yxx),h(p+1),f.x),f.y),f.z);
			}

			void V(uint i:SV_VertexID,out float4 c:SV_POSITION) {c=float4(((i<<1)&2)*2.-1,-2.*(i&2)+1,.1,1);}

			void P(float4 u:SV_POSITION, out float4 s:COLOR) 
			{	
				u = float4(9*u.xy/_ScreenParams,_Time.g,0);
				for (float i=0;i<1;i+=.02,u.y-=.1,u.w=(f(u)+f(u+9.5))*.5,s=l(s,u.w,smoothstep(0,1,(u.w-i)/fwidth(u.w)))){}
			}

			ENDCG
		}
	}
}