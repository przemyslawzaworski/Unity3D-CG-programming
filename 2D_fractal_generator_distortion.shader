Shader "2D Fractal Generator "
{
    Properties
    {
        I("Iteration",Int) = 50
        A("A",Range(0.01,2.0)) = 1.15
        B("B",Range(0.01,2.0)) = 0.95   
        C("C",Range(0.01,2.0)) = 0.48
        D("D",Range(0.00,2.0)) = 1.0    
        E("E",Range(0.00,2.0)) = 0   
        F("F",Range(0.00,2.0)) = 0.22
        G("G",Range(0.00,20.0)) = 1.4	
        U("U",Range(-5.0,5.0)) = 2.0
        V("V",Range(-5.0,5.0)) = 2.0
        X("X",Range(1.0,20.0)) = 5.0	
        Y("Y",Range(1.0,20.0)) = 5.0
        Z("Z",Range(1.0,20.0)) = 5.0	
        W("W",Range(1.0,20.0)) = 5.0
    }
    Subshader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vertex_shader
            #pragma fragment pixel_shader
            #pragma target 4.0

            int I;
            float A,B,C,D,E,F,G,U,V,X,Y,Z,W;

            struct custom_type
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
                        
            custom_type vertex_shader (float4 vertex:POSITION, float2 uv:TEXCOORD0)
            {
                custom_type vs;
                vs.vertex = mul(UNITY_MATRIX_MVP,vertex);
                vs.uv = uv;
                return vs;
            }

            float4 pixel_shader (custom_type ps) : SV_TARGET
            {
                float2 uv = float2(2.0*ps.uv.xy-1.0);
                uv.x+=cos(uv.y*X+_Time.g)/Y;
                uv.y+=sin(uv.x*Z+_Time.g)/W;
                float4 c = float4(uv.xy+float2(U,V),G,0);
                for (int i = 0; i < I; i++)
                {
                    c.xyz = float3(A,B,C)*abs(c.xyz/dot(c,c)-float3(D,E,F));    
                }
                return c;
            }
            
            ENDCG
        }
    }
}