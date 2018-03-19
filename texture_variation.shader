//Technique 3 from http://www.iquilezles.org/www/articles/texturerepetition/texturerepetition.htm

Shader "Texture variation"
{
	Properties
	{
		[Header(Select albedo texture then set tiling and offset)] 
		_MainTex ("Albedo texture", 2D) = "white" {}
		[Header(Noise texture for sample variation pattern)]
		_Noise("Noise texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
			#pragma target 3.0
			
			struct structure
			{
				float4 vertex:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex,_Noise;
			float4 _MainTex_ST;

			float3 texture_variation( sampler2D input, float2 uv )
			{
				float k = tex2D( _Noise, 0.005*uv ).x;  
				float2 dx = ddx( uv );
				float2 dy = ddy( uv );  
				float index = k*8.0;
				float i = floor( index );
				float f = frac( index ); 
				float2 offa = sin(float2(3.0,7.0)*(i+0.0)); 
				float2 offb = sin(float2(3.0,7.0)*(i+1.0)); 
				float3 cola = tex2Dgrad( input, uv + 0.9*offa, dx, dy ).xyz;
				float3 colb = tex2Dgrad( input, uv + 0.9*offb, dx, dy ).xyz; 
				float3 v = cola-colb;
				return lerp( cola, colb, smoothstep(0.2,0.8,f-0.1*(v.x+v.y+v.z)) );
			}
		
			void vertex_shader(in float4 vertex:POSITION,in float2 uv:TEXCOORD0,out structure vs) 
			{
				vs.vertex = UnityObjectToClipPos(vertex);
				vs.uv = uv; 
			}

			void pixel_shader(in structure ps, out float4 fragColor:SV_Target0) 
			{	
				float2 uv = ps.uv.xy;
				float3 color = texture_variation(_MainTex,uv*_MainTex_ST.xy+_MainTex_ST.zw).xyz;	
				fragColor = float4(color,1.0);
			}
			
			ENDCG
		}
	}
}