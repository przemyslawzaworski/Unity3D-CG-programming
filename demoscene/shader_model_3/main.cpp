//Microsoft Visual Studio 2015 C++
//Additional linker options: /CRINKLER /HASHSIZE:100 /COMPMODE:SLOW  /UNSAFEIMPORT 
//Renderer: DirectX 9.0c Shader Model 3.0
//Requires DirectX SDK
//Based on http://www.iquilezles.org/code/isystem1k4k/isystem1k4k.htm

#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#include <windows.h>
#include <d3d9.h>
#include <d3dx9.h>

static IDirect3DVertexShader9* vs = NULL;
static IDirect3DPixelShader9* ps = NULL;

static const float vertices[4 * 5] =
{
	1.0f,-1.0f,0.0f,1.0f,0.0f,
	-1.0f,-1.0f,0.0f,0.0f,0.0f,
	1.0f, 1.0f,0.0f,1.0f,1.0f,
	-1.0f, 1.0f,0.0f,0.0f,1.0f
};

static const char vertex_shader[] = \
"struct custom_type"
"{"
	"float4 p : POSITION;"
	"float2 u : TEXCOORD0;"
"};"

"custom_type vs_main(float4 p: POSITION, float2 u: TEXCOORD0)"
"{"
	"custom_type vs;"
	"vs.p = p;"
	"vs.u = u;"
	"return vs;"
"};"
;

static const char pixel_shader[] = \
"float timer : register(c0);"

"float noise(float3 n)"
"{"
	"return frac(sin(dot(n, float3(95.43583, 93.323197, 94.993431))) * 65536.32);"
"}"

"float perlin_a(float3 n)"
"{"
	"float3 base = floor(n * 64.0) * 0.015625;"
	"float3 dd = float3(0.015625, 0.0, 0.0);"
	"float a = noise(base);"
	"float b = noise(base + dd.xyy);"
	"float c = noise(base + dd.yxy);"
	"float d = noise(base + dd.xxy);"
	"float3 p = (n - base) * 64.0;"
	"float t = lerp(a, b, p.x);"
	"float tt = lerp(c, d, p.x);"
	"return lerp(t, tt, p.y);"
"}"

"float perlin_b(float3 n)"
"{"
	"float3 base = float3(n.x, n.y, floor(n.z * 64.0) * 0.015625);"
	"float3 dd = float3(0.015625, 0.0, 0.0);"
	"float3 p = (n - base) *  64.0;"
	"float front = perlin_a(base + dd.yyy);"
	"float back = perlin_a(base + dd.yyx);"
	"return lerp(front, back, p.z);"
"}"

"float fbm(float3 n)"
"{"
	"float total = 0.0;"
	"float m1 = 1.0;"
	"float m2 = 0.1;"
	"for (int i = 0; i < 5; i++)"
	"{"
		"total += perlin_b(n * m1) * m2;"
		"m2 *= 2.0;"
		"m1 *= 0.5;"
	"}"
	"return total;"
"}"

"float3 lava(float3 n)"
"{"
	"return float3(fbm((5.0 * n) + fbm((5.0 * n) * 3.0 - 1000.0) * 0.05),0,0);"
"}"


"float4 ps_main(in float2 u:texcoord):color"
"{"
	"return float4(float3((lava(float3(u.xy*5.0,timer*0.03)*0.05)-1.0)),1.0);"
"}";

void render(IDirect3DDevice9 *d3dDevice)
{
	d3dDevice->BeginScene();
	d3dDevice->SetVertexShader(vs);
	d3dDevice->SetPixelShader(ps);
	d3dDevice->SetFVF(D3DFVF_XYZ | D3DFVF_TEX1);
	float timer[4];
	timer[0] = GetTickCount()*0.001f;
	d3dDevice->SetPixelShaderConstantF(0, timer, 1);
	d3dDevice->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, vertices, 5 * sizeof(float));
	d3dDevice->EndScene();
	d3dDevice->Present(NULL, NULL, NULL, NULL);
}

static D3DPRESENT_PARAMETERS devParams = 
{
	1920, 1080, D3DFMT_A8R8G8B8, 0, D3DMULTISAMPLE_NONE,
	0, D3DSWAPEFFECT_DISCARD, 0, false, true,
	D3DFMT_D24S8, 0, 0, D3DPRESENT_INTERVAL_IMMEDIATE 
};

void entrypoint(void)
{
	IDirect3DDevice9 *d3dDevice;
	IDirect3D9 *d3d = Direct3DCreate9(D3D_SDK_VERSION);
	devParams.hDeviceWindow = CreateWindow("static", 0, WS_POPUP | WS_VISIBLE, 0, 0, 1920, 1080, 0, 0, 0, 0);
	d3d->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, devParams.hDeviceWindow, D3DCREATE_HARDWARE_VERTEXPROCESSING, &devParams, &d3dDevice);
	ShowCursor(0);
	ID3DXBuffer *ps_buffer = NULL;
	ID3DXBuffer *vs_buffer = NULL;
	D3DXCompileShader(vertex_shader, sizeof(vertex_shader), 0, 0, "vs_main", "vs_3_0", D3DXSHADER_USE_LEGACY_D3DX9_31_DLL, &vs_buffer, 0, 0);
	D3DXCompileShader(pixel_shader, sizeof(pixel_shader), 0, 0, "ps_main", "ps_3_0", D3DXSHADER_USE_LEGACY_D3DX9_31_DLL, &ps_buffer, 0, 0);
	d3dDevice->CreateVertexShader((DWORD*)vs_buffer->GetBufferPointer(), &vs);
	d3dDevice->CreatePixelShader((DWORD*)ps_buffer->GetBufferPointer(), &ps);
	do
	{
		render(d3dDevice);
	} 
	while (!GetAsyncKeyState(VK_ESCAPE));
	ExitProcess(0);
}