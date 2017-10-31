//reference: https://github.com/przemyslawzaworski/Unity3D-CG-programming/blob/master/procedural_font.shader

Shader "Procedural column chart"
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
			
			float _1(float2 uv) 
			{
				float2 pa = uv - float2(-0.2,0.45);
				float2 ba = float2(0.,0.6) - float2(-0.2,0.45);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return min(min(length(pa - ba * h),length(float2(uv.x,max(0.,abs(uv.y-.1)-.5)))),length(float2(max(0.,abs(uv.x)-.2),uv.y+.4)));          
			}

			float _2(float2 uv) 
			{
				float2 pa = uv - float2(0.185,0.17);
				float2 ba = float2(-.25,-.4) - float2(0.185,0.17);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				float x = min(length(pa - ba * h),length(float2(max(0.,abs(uv.x)-.25),uv.y+.4)));
				uv.y-=.35;
				uv.x += 0.025;
				return min(x,abs(atan2(uv.x,uv.y)-0.63)<1.64?abs(length(uv)-.275):length(uv+float2(.23,-.15)));
			}

			float _3(float2 uv) 
			{
				uv.y-=.1;
				uv.y = abs(uv.y);
				uv.y-=.25;
				return atan2(uv.x,uv.y)>-1.?abs(length(uv)-.25):min(length(uv+float2(.211,-.134)),length(uv+float2(.0,.25)));
			}

			float _4(float2 uv) 
			{
				float2 pa = uv - float2(0.15,0.6);
				float2 ba = float2(-.25,-.1) - float2(0.15,0.6);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);   
				float x = min(length(float2(uv.x-.15,max(0.,abs(uv.y-.1)-.5))),length(pa - ba * h));
				return min(x,length(float2(max(0.,abs(uv.x)-.25),uv.y+.1)));
			}

			float _5(float2 uv) 
			{
				float b = min(length(float2(max(0.,abs(uv.x)-.25),uv.y-.6)),length(float2(uv.x+.25,max(0.,abs(uv.y-.36)-.236))));
				uv.y += 0.1; uv.x += 0.05;
				float c = abs(length(float2(uv.x,max(0.,abs(uv.y)-.0)))-.3);
				return min(b,abs(atan2(uv.x,uv.y)+1.57)<.86 && uv.x<0.?length(uv+float2(.2,.224)):c);
			}

			float _6(float2 uv) 
			{
				uv.y-=.075;
				uv = -uv;
				float b = abs(length(float2(uv.x,max(0.,abs(uv.y)-.275)))-.25);
				uv.y-=.175;
				float c = abs(length(float2(uv.x,max(0.,abs(uv.y)-.05)))-.25);
				return min(c,cos(atan2(uv.x,uv.y+.45)+0.65)<0.||(uv.x>0.&& uv.y<0.)?b:length(uv+float2(0.2,0.6)));
			}

			float _7(float2 uv) 
			{
				float2 pa = uv - float2(-0.25,-0.39);
				float2 ba = float2(0.25,0.6) - float2(-0.25,-0.39);
				float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
				return min(length(float2(max(0.,abs(uv.x)-.25),uv.y-.6)),length(pa - ba * h));
			}

			float _8(float2 uv) 
			{
				float l = length(float2(max(0.,abs(uv.x)-.08),uv.y-.1+uv.x*.07));
				uv.y-=.1;
				uv.y = abs(uv.y);
				uv.y-=.245;
				return min(abs(length(uv)-.255),l);
			}

			float _9(float2 uv) 
			{
				uv.y-=.125;
				float b = abs(length(float2(uv.x,max(0.,abs(uv.y)-.275)))-.25);
				uv.y-=.175;
				float c = abs(length(float2(uv.x,max(0.,abs(uv.y)-.05)))-.25);
				return min(c,cos(atan2(uv.x,uv.y+.45)+0.65)<0.||(uv.x>0.&& uv.y<0.)?b:length(uv+float2(0.2,0.6)));
			}

			float _0(float2 uv) 
			{
				uv.y-=.1;
				return abs(length(float2(uv.x,max(0.,abs(uv.y)-.25)))-.25);
			}

			float C(float2 uv) 
			{
				float x = abs(length(float2(uv.x,max(0.,abs(uv.y-.1)-.25)))-.25);
				uv.y -= .1;
				uv.y= abs(uv.y);
				return uv.x<0.||atan2(uv.x,uv.y-0.25)<1.14?x:min(length(float2(uv.x+.25,max(0.0,abs(uv.y)-.25))), length(uv+float2(-.22734,-.354)));
			}

			float I(float2 uv) 
			{
				uv.y -= .1;
				float x = length(float2(uv.x,max(0.,abs(uv.y)-.5)));
				uv.y = abs(uv.y);
				return min(x,length(float2(max(0.,abs(uv.x)-.1),uv.y-.5)));
			}

			float U(float2 uv) 
			{
				return length(float2(abs(length(float2(uv.x,min(0.0,uv.y+.15) ))-0.25),max(0.,uv.y-.6)));
			}

			float S(float2 uv) 
			{
				uv.y -= .1;
				if (uv.y <.275-uv.x*.5 && uv.x>0. || uv.y<-.275-uv.x*.5) uv = -uv;
				float a = abs(length(float2(max(0.,abs(uv.x)),uv.y-.25))-.25);
				float b = length(float2(uv.x-.236,uv.y-.332));
				return atan2(uv.x-.05,uv.y-0.25)<1.14?a:b;
			}

			float A(float2 uv) 
			{
				float x = length(float2(abs(length(float2(uv.x,max(0.0,uv.y-.35) ))-0.25),min(0.,uv.y+.4)));
				return min(x,length(float2(max(0.,abs(uv.x)-.25),uv.y-.1) ));
			}

			float P(float2 uv) 
			{
				float x = length(float2(abs(length(float2(max(0.0,uv.x), uv.y-.35))-0.25),min(0.,uv.x+.25)));
				return min(x,length(float2(uv.x+.25,max(0.,abs(uv.y-.1)-.5)) ));
			}

			float TT(float2 uv) 
			{
				uv.y -= .1;
				float x = length(float2(uv.x,max(0.,abs(uv.y)-.5)));
				return min(x,length(float2(max(0.,abs(uv.x)-.25),uv.y-.5)));
			}

			float box(float2 p, float2 size, float radius)
			{
				float2 d = abs(p) - size;
				return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) ;   
			}	
			
			float remap (float x, float a, float b, float c, float d)  
			{
				return (x-a)/(b-a)*(d-c) + c; 
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
				float uu = remap (ps.uv.x,0,1,-2,2);
				float vv = remap (ps.uv.y,0,1,-1,1);
				float2 uv = float2(uu,vv);
				bool T[200] ;
				T[0] = C(uv*15.0+float2(20,13))<0.1;
				T[1] = h(uv*15.0+float2(19,13))<0.5;
				T[2] = i(uv*15.0+float2(18,13))<0.5;
				T[3] = n(uv*15.0+float2(17,13))<0.5;
				T[4] = a(uv*15.0+float2(16,13))<0.5;
				T[5] = I(uv*15.0+float2(12,13))<0.1;
				T[6] = n(uv*15.0+float2(11,13))<0.5;
				T[7] = d(uv*15.0+float2(10,13))<0.5;
				T[8] = i(uv*15.0+float2(9,13))<0.5;
				T[9] = a(uv*15.0+float2(8,13))<0.5;
				T[10] = U(uv*15.0+float2(4,13))<0.1;
				T[11] = S(uv*15.0+float2(3,13))<0.1;
				T[12] = A(uv*15.0+float2(2,13))<0.1;
				T[13] = I(uv*15.0+float2(-2,13))<0.1;
				T[14] = n(uv*15.0+float2(-3,13))<0.5;
				T[15] = d(uv*15.0+float2(-4,13))<0.5;    
				T[16] = o(uv*15.0+float2(-5,13))<0.5;
				T[17] = n(uv*15.0+float2(-6,13))<0.5;
				T[18] = e(uv*15.0+float2(-7,13))<0.5;
				T[19] = s(uv*15.0+float2(-8,13))<0.5;
				T[20] = i(uv*15.0+float2(-9,13))<0.5;
				T[21] = a(uv*15.0+float2(-10,13))<0.5;
				T[22] = P(uv*15.0+float2(-14,13))<0.1;
				T[23] = a(uv*15.0+float2(-15,13))<0.5;
				T[24] = k(uv*15.0+float2(-16,13))<0.5;    
				T[25] = i(uv*15.0+float2(-17,13))<0.5;
				T[26] = s(uv*15.0+float2(-18,13))<0.5;
				T[27] = t(uv*15.0+float2(-19,13))<0.5;
				T[28] = a(uv*15.0+float2(-20,13))<0.5;
				T[29] = n(uv*15.0+float2(-21,13))<0.5;
        
				T[40] = box(uv+float2(1.2,0.05),float2(0.05,0.7),0.0)<0.02;
				T[41] = box(uv+float2(0.65,0.07),float2(0.05,0.67),0.0)<0.02;
				T[42] = box(uv+float2(0.2,0.56),float2(0.05,0.18),0.0)<0.02;
				T[43] = box(uv+float2(-0.4,0.6),float2(0.05,0.13),0.0)<0.02;
				T[44] = box(uv+float2(-1.15,0.62),float2(0.05,0.11),0.0)<0.02;
    
				T[50] = _1(uv*15.0+float2(25.5,9))<0.1;
				T[51] = _0(uv*15.0+float2(24.5,9))<0.1;
				T[52] = _0(uv*15.0+float2(23.5,9))<0.1;
				T[53] = _3(uv*15.0+float2(25.5,6))<0.1;
				T[54] = _0(uv*15.0+float2(24.5,6))<0.1;
				T[55] = _0(uv*15.0+float2(23.5,6))<0.1;
				T[56] = _5(uv*15.0+float2(25.5,3))<0.1;
				T[57] = _0(uv*15.0+float2(24.5,3))<0.1;
				T[58] = _0(uv*15.0+float2(23.5,3))<0.1;
				T[59] = _7(uv*15.0+float2(25.5,0))<0.1;
				T[60] = _0(uv*15.0+float2(24.5,0))<0.1;
				T[61] = _0(uv*15.0+float2(23.5,0))<0.1;
				T[62] = _9(uv*15.0+float2(25.5,-3))<0.1;
				T[63] = _0(uv*15.0+float2(24.5,-3))<0.1;
				T[64] = _0(uv*15.0+float2(23.5,-3))<0.1;
				T[65] = _1(uv*15.0+float2(26,-6))<0.1;
				T[66] = _1(uv*15.0+float2(25,-6))<0.1;
				T[67] = _0(uv*15.0+float2(24,-6))<0.1;
				T[68] = _0(uv*15.0+float2(23,-6))<0.1;
				T[69] = _1(uv*15.0+float2(26,-9))<0.1;
				T[70] = _3(uv*15.0+float2(25,-9))<0.1;
				T[71] = _0(uv*15.0+float2(24,-9))<0.1;
				T[72] = _0(uv*15.0+float2(23,-9))<0.1;
				T[73] = m(uv*15.0+float2(25,-11.5))<0.5;
				T[74] = n(uv*15.0+float2(24,-11.5))<0.5;
    
				T[80] = box(uv+float2(0,0.6),float2(1.45,0.001),0.0)<0.005;
				T[81] = box(uv+float2(0,0.5),float2(1.45,0.001),0.0)<0.005;
				T[82] = box(uv+float2(0,0.4),float2(1.45,0.001),0.0)<0.005;
				T[83] = box(uv+float2(0,0.3),float2(1.45,0.001),0.0)<0.005;
				T[84] = box(uv+float2(0,0.2),float2(1.45,0.001),0.0)<0.005;
				T[85] = box(uv+float2(0,0.1),float2(1.45,0.001),0.0)<0.005;
				T[86] = box(uv+float2(0,0.0),float2(1.45,0.001),0.0)<0.005;
				T[87] = box(uv+float2(0,-0.1),float2(1.45,0.001),0.0)<0.005;
				T[88] = box(uv+float2(0,-0.2),float2(1.45,0.001),0.0)<0.005; 
				T[89] = box(uv+float2(0,-0.3),float2(1.45,0.001),0.0)<0.005; 
				T[90] = box(uv+float2(0,-0.4),float2(1.45,0.001),0.0)<0.005;
				T[91] = box(uv+float2(0,-0.5),float2(1.45,0.001),0.0)<0.005;
				T[92] = box(uv+float2(0,-0.6),float2(1.45,0.001),0.0)<0.005; 
				T[93] = box(uv+float2(0,-0.7),float2(1.45,0.001),0.0)<0.005; 
    
				T[100] = TT(uv*15.0+float2(21,-13))<0.1;
				T[101] = o(uv*15.0+float2(20,-13))<0.5;
				T[102] = p(uv*15.0+float2(19,-13))<0.5;
    
				T[103] = _5(uv*15.0+float2(17,-13))<0.1;

				T[104] = m(uv*15.0+float2(15,-13))<0.5;
				T[105] = o(uv*15.0+float2(14,-13))<0.5;
				T[106] = s(uv*15.0+float2(13,-13))<0.5;
				T[107] = t(uv*15.0+float2(12,-13))<0.5;
		
				T[108] = p(uv*15.0+float2(10,-13))<0.5;
				T[109] = o(uv*15.0+float2(9,-13))<0.5;
				T[110] = p(uv*15.0+float2(8,-13))<0.5;
				T[111] = u(uv*15.0+float2(7,-13))<0.5;
				T[112] = l(uv*15.0+float2(6,-13))<0.5;
				T[113] = a(uv*15.0+float2(5,-13))<0.5;
				T[114] = t(uv*15.0+float2(4,-13))<0.5;
				T[115] = e(uv*15.0+float2(3,-13))<0.5;
				T[116] = d(uv*15.0+float2(2,-13))<0.5;

				T[117] = c(uv*15.0+float2(0,-13))<0.5;
				T[118] = o(uv*15.0+float2(-1,-13))<0.5;
				T[119] = u(uv*15.0+float2(-2,-13))<0.5;
				T[120] = n(uv*15.0+float2(-3,-13))<0.5;
				T[121] = t(uv*15.0+float2(-4,-13))<0.5;
				T[122] = r(uv*15.0+float2(-5,-13))<0.5;
				T[123] = i(uv*15.0+float2(-6,-13))<0.5;
				T[124] = e(uv*15.0+float2(-7,-13))<0.5;
				T[125] = s(uv*15.0+float2(-8,-13))<0.5;

				T[126] = i(uv*15.0+float2(-10,-13))<0.5;
				T[127] = n(uv*15.0+float2(-11,-13))<0.5;

				T[128] = t(uv*15.0+float2(-13,-13))<0.5;
				T[129] = h(uv*15.0+float2(-14,-13))<0.5;
				T[130] = e(uv*15.0+float2(-15,-13))<0.5;

				T[131] = w(uv*15.0+float2(-17,-13))<0.5;
				T[132] = o(uv*15.0+float2(-18,-13))<0.5;
				T[133] = r(uv*15.0+float2(-19,-13))<0.5;
				T[134] = l(uv*15.0+float2(-20,-13))<0.5;
				T[135] = d(uv*15.0+float2(-21,-13))<0.5;

				if(T[40] || T[41] || T[42] || T[43] || T[44] ) return float4(1.0-pow(0.1,uv.y + 1.0 ),0,0,1);
				else
				if
				( T[0]  || T[1]  || T[2]  || T[3]  || T[4]  || T[5]  || T[6]  || T[7]  || T[8]  || T[9]  || T[10] || 
					T[11] || T[12] || T[13] || T[14] || T[15] || T[16] || T[17] || T[18] || T[19] || T[20] || T[21] ||
					T[22] || T[23] || T[24] || T[25] || T[26] || T[27] || T[28] || T[29] ||T[80]  || T[81] || T[82] ||
					T[83] || T[84] || T[85] || T[86] || T[87] || T[88] || T[89] || T[90] || T[91] || T[92] || T[93] || 
					T[100]|| T[101]|| T[102]|| T[103]|| T[104]|| T[105]|| T[106]|| T[107]|| T[108]|| T[109]|| T[110]||
					T[111]|| T[112]|| T[113]|| T[114]|| T[115]|| T[116]|| T[117]|| T[118]|| T[119]|| T[120]|| T[121]|| 
					T[122]|| T[123]|| T[124]|| T[125]|| T[126]|| T[127]|| T[128]|| T[129]|| T[130]|| T[131]|| T[132]|| 
					T[133]|| T[134]|| T[135] ) return  float4(0,0,0,1);   
				else if(T[50] || T[51] || T[52] || T[53] || T[54] || T[55] || T[56] || T[57] || T[58] || T[59] || T[60] ||
						T[61] || T[62] || T[63] || T[64] || T[65] || T[66] || T[67] || T[68] || T[69] || T[70] || T[71] ||
						T[72] || T[73] || T[74]) return  float4(0,0,1,1);
				else return float4(0.93,0.93,0.5*abs(uv.x),0.93);
			}
			ENDCG
		}
	}
}