//reference: https://www.shadertoy.com/view/lddXzM
//digits and other signs will be added later

Shader "Procedural font"
{
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0

			struct custom_type
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float a(float2 uv) 
			{
				uv = -uv;
				float x = abs(length(float2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4;
				x = min(x,length(float2(uv.x+.25,max(0.,abs(uv.y-.2)-.2)))+.4);
				return min(x,(uv.x<0.?uv.y<0.:atan2(uv.x,uv.y+0.15)>2.)?abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4:length(float2(uv.x-.22734,uv.y+.254))+.4);
			}

			float b(float2 uv) 
			{
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
				uv.x += .25;
				uv.y -= .2;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4);
			}

			float c(float2 uv) 
			{
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
				uv.y= abs(uv.y);
				return uv.x<0.||atan2(uv.x,uv.y-0.15)<1.14?x:length(float2(uv.x-.22734,uv.y-.254))+.4;
			}

			float d(float2 uv) 
			{
				uv.x *= -1.;
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
				uv.x += .25;
				uv.y -= .2;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4);
			}

			float e(float2 uv) 
			{
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;;
				return min(uv.x<0.||uv.y>.05||atan2(uv.x,uv.y+0.15)>2.?x:length(float2(uv.x-.22734,uv.y+.254))+.4,length(float2(max(0.,abs(uv.x)-.25),uv.y-.05))+.4);
			}

			float f(float2 uv) 
			{
				uv.x *= -1.;
				uv.x += .05;
				float2 uv2 = float2(uv.x,-uv.y);
				uv2.x+=.2;
				float t = length(float2(abs(length(float2(uv2.x,max(0.0,-(.4+.15)-uv2.y) ))-.25),max(0.,uv2.y-.4))) +.4;
				float x = uv2.x>0.?t:length(float2(uv2.x,uv2.y+.8))+.4;
				uv.y -= .4;
				return min(x,length(float2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
			}

			float g(float2 uv) 
			{
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;;
				return min(x,uv.x>0.||uv.y<-.65?length(float2(abs(length(float2(uv.x,max(0.0,-(.4+0.2)-uv.y) ))-.25),max(0.,uv.y-.4)))+.4:length(float2(uv.x+0.25,uv.y+.65))+.4 );
			}

			float h(float2 uv) 
			{
				uv.y *= -1.;
				float x =  length(float2(abs(length(float2(uv.x,max(0.0,-(.4-.25)-uv.y) ))-.25),max(0.,uv.y-.4))) +.4;
				uv.x += .25;
				uv.y *= -1.;
				uv.y -= .2;
				float l = length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4;
				return min(x,l);
			}

			float i(float2 uv) 
			{
				return min(length(float2(uv.x,max(0.,abs(uv.y)-.4)))+.4,length(float2(uv.x,uv.y-.7))+.4);
			}

			float j(float2 uv) 
			{
				uv.x += .05;
				float2 uv2=uv;
				uv2.x+=.2;
				float t = length(float2(abs(length(float2(uv2.x,max(0.0,-(.4+.15)-uv2.y) ))-.25),max(0.,uv2.y-.4))) +.4;
				float x = uv2.x>0.?t:length(float2(uv2.x,uv2.y+.8))+.4;
				return min(x,length(float2(uv.x-.05,uv.y-.7))+.4);
			}

			float k(float2 uv) 
			{
				float2 pa1 = uv - float2(-.25,-.1);
				float2 ba1 = float2(0.25,0.4) - float2(-.25,-.1);
				float h1 = clamp(dot(pa1, ba1) / dot(ba1, ba1), 0.0, 1.0);       
				float x = length(pa1 - ba1 * h1)+.4;
				float2 pa2 = uv - float2(-.15,.0);
				float2 ba2 = float2(0.25,-0.4) - float2(-.15,.0);
				float h2 = clamp(dot(pa2, ba2) / dot(ba2, ba2), 0.0, 1.0);       
				float y = length(pa2 - ba2 * h2)+.4;  
				x = min(x,y);
				uv.x+=.25; 
				uv.y -= .2;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4);
			}

			float l(float2 uv) 
			{
				uv.y -= .2;
				return length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4;
			}

			float m(float2 uv) 
			{
				uv.y *= -1.;
				uv.x-=.175;
				float x = length(float2(abs(length(float2(uv.x,max(0.0,-(.4-0.175)-uv.y) ))-0.175),max(0.,uv.y-.4))) +.4;
				uv.x+=.35;
				x = min(x,length(float2(abs(length(float2(uv.x,max(0.0,-(.4-0.175)-uv.y) ))-0.175),max(0.,uv.y-.4))) +.4);
				uv.x+=.175;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.4)))+.4);
			}

			float n(float2 uv) 
			{
				uv.y *= -1.;
				float x = length(float2(abs(length(float2(uv.x,max(0.0,-(.4-0.25)-uv.y) ))-0.25),max(0.,uv.y-.4))) +.4;
				uv.x+=.25;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.4)))+.4);
			}

			float o(float2 uv)
			{
				return abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
			}

			float p(float2 uv) 
			{
				float x =abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
				uv.x += .25;
				uv.y += .4;
				uv.y -= .2;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4);
			}

			float q(float2 uv) 
			{
				uv.x = -uv.x;
				float x =abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
				uv.x += .25;
				uv.y += .4;
				uv.y -= .2;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.6)))+.4);
			}

			float r(float2 uv) 
			{
				float x =atan2(uv.x,uv.y-0.15)<1.14&&uv.y>0.?abs(length(float2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4:length(float2(uv.x-.22734,uv.y-.254))+.4; 
				uv.x+=.25;
				return min(x,length(float2(uv.x,max(0.,abs(uv.y)-.4)))+.4);
			}

			float s(float2 uv) 
			{    
				if (uv.y <.145 && uv.x>0. || uv.y<-.145) uv = -uv; 
				return atan2(uv.x-.05,uv.y-0.2)<1.14?abs(length(float2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4:length(float2(uv.x-.231505,uv.y-.284))+.4;
			}

			float t(float2 uv) 
			{
				uv.x *= -1.;
				uv.y -= .4;
				uv.x += .05;
				float2 uv2 = uv;
				uv2.x+=.2;
				float t = length(float2(abs(length(float2(uv2.x,max(0.0,-(.4+.15)-uv2.y) ))-.25),max(0.,uv2.y-.4))) +.4;
				float x = uv2.x>0.?t:length(float2(uv2.x,uv2.y+.8))+.4;
				return min(x,length(float2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
			}

			float u(float2 uv) 
			{
				return length(float2(abs(length(float2(uv.x,max(0.0,-(.4-0.25)-uv.y) ))-0.25),max(0.,uv.y-.4))) +.4;
			}

			float v(float2 uv) 
			{
				uv.x=abs(uv.x);
				float2 pa = uv - float2(0.25,0.4);
				float2 ba = float2(0.,-0.4) - float2(0.25,0.4);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return length(pa - ba * h)+.4;
			}

			float w(float2 uv) 
			{
				uv.x=abs(uv.x);
				float2 pa1 = uv - float2(0.3,0.4);
				float2 ba1 = float2(.2,-0.4) - float2(0.3,0.4);
				float h1 = clamp(dot(pa1, ba1) / dot(ba1, ba1), 0.0, 1.0);
				float2 pa2 = uv - float2(0.2,-0.4);
				float2 ba2 = float2(0.,0.1) - float2(0.2,-0.4);
				float h2 = clamp(dot(pa2, ba2) / dot(ba2, ba2), 0.0, 1.0);
				return min(length(pa1 - ba1 * h1)+.4,length(pa2 - ba2 * h2)+.4);
			}

			float x(float2 uv) 
			{
				uv=abs(uv);
				float2 pa = uv ;
				float2 ba = float2(.3,0.4) ;
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return length(pa - ba * h)+.4;
			}

			float y(float2 uv)
			{
				float2 pa1 = uv - float2(.0,-.2);
				float2 ba1 = float2(-.3,0.4) - float2(.0,-.2);
				float h1 = clamp(dot(pa1, ba1) / dot(ba1, ba1), 0.0, 1.0);
				float2 pa2 = uv - float2(.3,.4);
				float2 ba2 = float2(-.3,-0.8) - float2(.3,.4);
				float h2 = clamp(dot(pa2, ba2) / dot(ba2, ba2), 0.0, 1.0);
				return min(length(pa1 - ba1 * h1)+.4,length(pa2 - ba2 * h2)+.4);
			}

			float z(float2 uv) 
			{
				float2 pa = uv - float2(0.25,0.4);
				float2 ba = float2(-0.25,-0.4)- float2(0.25,0.4);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);   
				float l = length(pa-ba * h)+.4;
				uv.y=abs(uv.y);
				float x = length(float2(max(0.,abs(uv.x)-.25),uv.y-.4))+.4;
				return min(x,l);
			}
		
			custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
			{
				custom_type vs;
				vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
				vs.uv = uv;
				return vs;
			}

			float4 pixel_shader (custom_type ps) : COLOR
			{
				float2 uv = float2(2.0*ps.uv.xy-1.0);
				bool T[10] ;
				T[0] = h(uv*5.0+float2(2,-1))<0.5;
				T[1] = e(uv*5.0+float2(1,-1))<0.5;
				T[2] = l(uv*5.0+float2(0,-1))<0.5;
				T[3] = l(uv*5.0+float2(-1,-1))<0.5;
				T[4] = o(uv*5.0+float2(-2,-1))<0.5;	
				T[5] = w(uv*5.0+float2(2,1))<0.5;
				T[6] = o(uv*5.0+float2(1,1))<0.5;
				T[7] = r(uv*5.0+float2(0,1))<0.5;
				T[8] = l(uv*5.0+float2(-1,1))<0.5;
				T[9] = d(uv*5.0+float2(-2,1))<0.5;				
				if (T[0]||T[1]||T[2]||T[3]||T[4]||T[5]||T[6]||T[7]||T[8]||T[9]) return float4(1,1,1,1);	else return float4(0,0,0,1);
			}
			ENDCG
		}
	}
}