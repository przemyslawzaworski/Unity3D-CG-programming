/*
	Copyright (c) 2018 Przemyslaw Zaworski

	MIT licence
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

Shader "Liquid" 
{
	Properties 
	{
		_MainColor ("Main Color", Color) = (1,1,1,1)
		_Volume ("Volume", Range(-2,2)) = 0.0
		_WaveColor ("Wave Color", Color) = (1,1,1,1)
		_WaveSpeed ("Wave Speed", Float) = 1.0
		_GlobalWaveSpeed ("Global Wave Speed", Float) = 1.0	
		_GlobalWaveHeight ("Global Wave Height", Float) = 0.1
		[Toggle] _enable("Enable detail", Float) = 1		
		_DetailSpeed ("Detail Wave Speed", Float) = 1.0	
		_DetailDensity ("Detail Wave Resolution", Float) = 10.0		
		_RimColor ("Density Color", Color) = (1,1,1,1)
		_RimPower ("Density Power", Range(0,10)) = 0.0
	}
	
	SubShader 
	{
		Pass
		{
			Zwrite On
			Cull Off 
			AlphaToMask On 
			CGPROGRAM
			#pragma vertex vertex_shader
			#pragma fragment pixel_shader
 
			float _Volume, _RimPower, _WaveSpeed, _GlobalWaveSpeed, _GlobalWaveHeight;
			float _DetailDensity, _DetailSpeed, _enable;
			float4 _WaveColor, _RimColor, _MainColor;
           
			float3 ObjSpaceViewDir( in float4 v )
			{
				return mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz - v.xyz;
			}

			float hash(float2 n) 
			{ 
				return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
			}

			float noise(float2 p)
			{
				float2 i = floor( p );
				float2 f = frac( p );	
				float2 u = f*f*(3.0-2.0*f);
				return lerp( lerp( dot( hash( i + float2(0.0,0.0) ), f - float2(0.0,0.0) ), 
					dot( hash( i + float2(1.0,0.0) ), f - float2(1.0,0.0) ), u.x),
					lerp( dot( hash( i + float2(0.0,1.0) ), f - float2(0.0,1.0) ), 
					dot( hash( i + float2(1.0,1.0) ), f - float2(1.0,1.0) ), u.x), u.y);
			}

			float2x2 rotation( float x) 
			{
				return float2x2 (cos(x),sin(x),-sin(x),cos(x));
			}
			
			void vertex_shader (inout float4 vertex:POSITION,inout float3 normal:NORMAL,inout float2 uv:TEXCOORD0,out float level:TEXCOORD2,out float3 viewDir:TEXCOORD3)
			{
				float3 Point = mul (unity_ObjectToWorld, vertex.xyz);
				Point.xz = mul(rotation(_Time.g * _GlobalWaveSpeed),Point.xz);
				if (_enable)
					level = (Point.y + noise(_DetailDensity*uv+_Time.g*_DetailSpeed) + Point.x * _GlobalWaveHeight + Point.z * _GlobalWaveHeight + _Volume);
				else
					level = (Point.y + Point.x * _GlobalWaveHeight + Point.z * _GlobalWaveHeight + _Volume);					
				viewDir = normalize(ObjSpaceViewDir(vertex));
				vertex = UnityObjectToClipPos(vertex);
			}
			
			float4 pixel_shader (in float4 vertex:POSITION,in float3 normal:NORMAL,in float2 uv:TEXCOORD0,in float level:TEXCOORD2,in float3 viewDir:TEXCOORD3, float side:VFACE) : SV_Target
			{
				float4 border = step(level, 0.5) ;
				float4 TotalColor = border * _MainColor;
				TotalColor.rgb += smoothstep(0.5, 1.0, 1.0 - pow(dot(normal, viewDir), _RimPower)) * _RimColor;
				float4 WaveColor = float4(_WaveColor.rgb + noise (uv*10.0+_Time.g*_WaveSpeed)*0.3,_WaveColor.a) * border;
				return (side>0.0) ? TotalColor : WaveColor;
			}
			ENDCG
		}
	}
}