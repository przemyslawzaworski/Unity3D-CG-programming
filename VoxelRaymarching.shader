// Add built-in Cube with position (0,0,0) and scale (50, 50, 50). Assign material to cube.
// Reference: https://www.shadertoy.com/view/33dXzH
Shader "Voxel Raymarching"
{
	Properties
	{	
		[Enum(MaxNormSDFMarching,1,FloatDDA,2,DivisionFreeDDA,3,SumOnlyDDA,4)] _Technique ("Technique", Int) = 1	
	}
	Subshader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex VSMain
			#pragma fragment PSMain
			#pragma target 5.0

			int _Technique;

			float Sphere(float3 p, float3 c, float s)
			{
				return length(p - c) - s;
			}

			bool Voxel(float3 p) 
			{
				return Sphere(p, float3(0,0,0), 25.0) < 0.0; 
			}

			float MaxNormSDFMarching(float3 ro, float3 rd)
			{
				float i = 1., r;
				for ( ; i < 200. ; i++)
				{
					r = .5;
					float3 q = floor(ro), b, d;
					for (d.x=0. ; d.x<2. ; d.x++)
					for (d.y=0. ; d.y<2. ; d.y++)
					for (d.z=0. ; d.z<2. ; d.z++)
					if (Voxel(q + d))
					{
						b = abs(q + d - ro);
						r = min(r, max(b.x, max(b.y, b.z)) - .5);
					}
					if (r < 1e-3)
						break;
					ro += r * rd;
				}
				return 3. / (i + r / 7e-4);
			}

			float FloatDDA(float3 ro, float3 rd)
			{
				ro += .5;
				float3 q = floor(ro), next;
				for (int i=1 ; !Voxel(q) && i < 200 ; i++)
				{
					float3 code = ((q + .5 - ro) * sign(rd) + .5) / abs(rd);
					next = code.x <= min(code.y, code.z) ? float3(1,0,0) : code.y <= code.z ? float3(0,1,0) : float3(0,0,1);
					q += sign(rd) * next;
				}
				
				float r = dot((q + .5 - ro) * sign(rd) - .5, next) / dot(abs(rd), next);
				return 3. * sqrt(dot(abs(rd), next)) / (2. + r) / 2.;
			}

			float DivisionFreeDDA(float3 ro, float3 rd) 
			{
				ro += .5;
				float3 q = floor(ro), next;
				for (int i=1 ; !Voxel(q) && i < 200 ; i++)
				{
					float3 code = cross((q + .5 - ro) * sign(rd) + .5, abs(rd));
					next = code.z<=0.&&code.y>=0. ? float3(1,0,0) : code.x<=0. ? float3(0,1,0) : float3(0,0,1);
					q += sign(rd) * next;
				}			
				float r = dot((q + .5 - ro) * sign(rd) - .5, next) / dot(abs(rd), next);
				return 3. * sqrt(dot(abs(rd), next)) / (2. + r) / 2.;
			}

			float SumOnlyDDA(float3 ro, float3 rd)
			{
				ro += .5;
				float3 q = floor(ro), code = cross((q + .5 - ro) * sign(rd) + .5, abs(rd));
				float3x3 delta = float3x3(0,-abs(rd.z),abs(rd.y), abs(rd.z),0,-abs(rd.x), -abs(rd.y),abs(rd.x),0);
				int i = 1, next;
				for ( ; !Voxel(q) && i < 200 ; i++)
				{
					next = code.z<=0.&&code.y>=0. ? 0 : code.x<=0. ? 1 : 2;
					code += delta[next];
					if (next == 0)
						q[0] += sign(rd).x;
					else if (next == 1)
						q[1] += sign(rd).y;
					else
						q[2] += sign(rd).z;
				} 
				float r = (((q + .5 - ro) * sign(rd) - .5) / abs(rd))[next];
				return 3. * sqrt(abs(rd)[next]) / (2. + r) / 2.;
			}

			float4 VSMain (float4 vertex : POSITION, out float3 worldPos : TEXCOORD1) : SV_POSITION
			{
				worldPos = mul(unity_ObjectToWorld, vertex);
				return UnityObjectToClipPos(vertex);
			}

			float4 PSMain (float4 vertex : SV_POSITION, float3 worldPos : TEXCOORD1) : SV_TARGET
			{
				float3 worldPosition = worldPos;
				float3 viewDirection = normalize(worldPos - _WorldSpaceCameraPos.xyz);
				switch(_Technique)
				{
					case 1: return (float4) MaxNormSDFMarching(worldPosition, viewDirection);
					case 2: return (float4) FloatDDA(worldPosition, viewDirection); 
					case 3: return (float4) DivisionFreeDDA(worldPosition, viewDirection); 
					case 4: return (float4) SumOnlyDDA(worldPosition, viewDirection);
					default: return float4(0,0,0,1); 
				}
			}
			ENDCG
		}
	}
}