//source: https://www.shadertoy.com/view/XtVGD1
//Notebook drawings post processing fullscreen effect.
//Include notebook_drawings.cs to Main Camera and material with shader.
//Removed noise for better performance.

Shader "Notebook Drawings"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		SampNum ("Sample count", Int) = 8
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM		
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 4.0
			
			sampler2D _MainTex;
			int SampNum;

			float4 getCol(float2 pos)
			{
				float2 uv=((pos-_ScreenParams.xy*.5)/_ScreenParams.y*_ScreenParams.y)/_ScreenParams.xy+.5;
				uv.y=1.0-uv.y;
				float4 c1=tex2Dlod(_MainTex,float4(uv,0,0));
				float4 e=smoothstep(float4(-0.05,-0.05,-0.05,-0.05),float4(0,0,0,0),float4(uv,float2(1,1)-uv));
				c1=lerp(float4(1,1,1,0),c1,e.x*e.y*e.z*e.w);
				float d=clamp(dot(c1.xyz,float3(-.5,1.,-.5)),0.0,1.0);
				float4 c2=float4(0.7,0.7,0.7,0.7);
				return min(lerp(c1,c2,1.8*d),.7);
			}

			float4 getColHT(float2 pos)
			{
				return getCol(pos);
			}

			float getVal(float2 pos)
			{
				float4 c=getCol(pos);
				return pow(dot(c.xyz,float3(0.333,0.333,0.333)),1.)*1.;
			}

			float2 getGrad(float2 pos, float eps)
			{
				float2 d=float2(eps,0);
				return float2(
					getVal(pos+d.xy)-getVal(pos-d.xy),
					getVal(pos+d.yx)-getVal(pos-d.yx)
				)/eps/2.;
			}

			float4 vertex_shader (float4 vertex : POSITION) : SV_POSITION
			{
				return  UnityObjectToClipPos (vertex);
			}

			float4 pixel_shader (float4 vertex:SV_POSITION) : SV_TARGET
			{
				float2 pos = vertex.xy+4.0*sin(float2(1,1.7))*_ScreenParams.y/400.0;
				float3 col = float3(0,0,0);
				float3 col2 = float3(0,0,0);
				float sum=0.0;
				for(int i=0;i<3;i++)
				{
					float ang= 6.28318530717959/3.0*(float(i)+.8);
					float2 v=float2(cos(ang),sin(ang));
					for(int j=0;j<SampNum;j++)
					{
						float2 dpos  = v.yx*float2(1,-1)*float(j)*_ScreenParams.y/400.;
						float2 dpos2 = v.xy*float(j*j)/float(SampNum)*.5*_ScreenParams.y/400.;
						float2 g;
						float fact,fact2;
						for(float s=-1.;s<=1.;s+=2.)
						{
							float2 pos2=pos+s*dpos+dpos2;
							float2 pos3=pos+(s*dpos+dpos2).yx*float2(1,-1)*2.;
							g=getGrad(pos2,.4);
							fact=dot(g,v)-.5*abs(dot(g,v.yx*float2(1,-1)))/**(1.-getVal(pos2))*/;
							fact2=dot(normalize(g+float2(.0001,.0001)),v.yx*float2(1,-1));							
							fact=clamp(fact,0.0,0.05);
							fact2=abs(fact2);							
							fact*=1.-float(j)/float(SampNum);
							col += fact;
							col2 += fact2*getColHT(pos3).xyz;
							sum+=fact2;
						}
					}
				}
				col/=float(SampNum*3)*.75/sqrt(_ScreenParams.y);
				col2/=sum;
				col.x=1.-col.x;
				col.x*=col.x*col.x;
				float2 s=sin(pos.xy*.1/sqrt(_ScreenParams.y/400.));
				float3 karo=float3(1,1,1);
				karo-=.5*float3(.25,.1,.1)*dot(exp(-s*s*80.),float2(1,1));
				float r=length(pos-_ScreenParams.xy*.5)/_ScreenParams.x;
				float vign=1.-r*r*r;
				return float4(float3(col.x*col2*karo*vign),1);
			}
			ENDCG
		}
	}
}