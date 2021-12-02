Shader "Bake Vertex Color Map"
{
    SubShader
    {
        Pass
        {
            ZTest Off
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma vertex VSMain
            #pragma fragment PSMain
 
            void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0, inout float4 color:COLOR)
            {
                float2 texcoord = uv.xy;
                texcoord.y = 1.0 - texcoord.y;
                texcoord = texcoord * 2.0 - 1.0;
                vertex = float4(texcoord, 0.0, 1.0);
            }
 
            float4 PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, float4 color:COLOR) : SV_TARGET
            {
                return color;
            }
            ENDCG
        }
    }
}