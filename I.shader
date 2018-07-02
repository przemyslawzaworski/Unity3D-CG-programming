//626 chars
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
			
			half k(half3 x)
			{
				half3 p = floor(x),f = frac(x),n = {1,0,0},t = {1,9,57}; f *= f*(3-2*f); 
				#define h(m) frac(cos(dot(m,t))*1e5)
				return l(l(l(h(p),h(p+n.xyy),f.x),l(h(p+n.yxy),h(p+n.xxy),f.x),f.y),l(l(h(p+n.yyx),h(p+n.xyx),f.x),l(h(p+n.yxx),h(p+1),f.x),f.y),f.z);
			}
			
			void V(uint i:SV_VertexID,out half4 c:POSITION) {c=half4(((i<<1)&2)*2.-1,-2.*(i&2)+1,1,1);}

			void P(half4 u:POSITION,out half s:COLOR) 
			{	
				u = half4(9*u.xy/_ScreenParams,_Time.g,0);
				for (half i;i<1;i+=.02,u.y-=.1,u.w=(k(u)+k(u+9.5))/2,s=l(s,u.w,smoothstep(0,1,(u.w-i)/fwidth(u.w)))){}
			}

			ENDCG
		}
	}
}