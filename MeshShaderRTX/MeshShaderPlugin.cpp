// For x64 Visual Studio command line:  cl.exe /LD MeshShaderPlugin.cpp opengl32.lib
#include <windows.h>
#include <GL/gl.h>

typedef GLuint(WINAPI *PFNGLCREATEPROGRAMPROC) ();
typedef GLuint(WINAPI *PFNGLCREATESHADERPROC) (GLenum t);
typedef void(WINAPI *PFNGLSHADERSOURCEPROC) (GLuint s, GLsizei c, const char*const*string, const GLint* i);
typedef void(WINAPI *PFNGLCOMPILESHADERPROC) (GLuint s);
typedef void(WINAPI *PFNGLATTACHSHADERPROC) (GLuint p, GLuint s);
typedef void(WINAPI *PFNGLLINKPROGRAMPROC) (GLuint p);
typedef void(WINAPI *PFNGLUSEPROGRAMPROC) (GLuint p);
typedef void(WINAPI *PFNGLGETSHADERIVPROC) (GLuint s, GLenum v, GLint *p);
typedef void(WINAPI *PFNGLGETSHADERINFOLOGPROC) (GLuint s, GLsizei b, GLsizei *l, char *i);
typedef void(WINAPI *PFNGLDRAWMESHTASKSNVPROC) (GLuint f, GLuint c);

unsigned int PS;

static const char* MeshShader = \
	"#version 450 \n"
	"#extension GL_NV_mesh_shader : enable\n"
	"layout(local_size_x = 3) in;"
	"layout(max_vertices = 64) out;"
	"layout(max_primitives = 126) out;"
	"layout(triangles) out;"
	"const vec3 vertices[3] = {vec3(-1,-1,0), vec3(1,-1,0), vec3(0,1,0)};"
	"void main()"
	"{"
		"uint id = gl_LocalInvocationID.x;"
		"gl_MeshVerticesNV[id].gl_Position = vec4(vertices[id], 2);"
		"gl_PrimitiveIndicesNV[id] = id;"
		"gl_PrimitiveCountNV = 1;"
	"}";
	
static const char* FragmentShader = \
	"#version 450 \n"
	"#extension GL_NV_fragment_shader_barycentric : enable\n"
	"out vec4 color;"
	"void main()"
	"{"	
		"color = vec4(gl_BaryCoordNV, 1.0);"
	"}";

int MakeShaders(const char* MS, const char* FS)
{
	int p = ((PFNGLCREATEPROGRAMPROC)wglGetProcAddress("glCreateProgram"))();
	int sm = ((PFNGLCREATESHADERPROC)wglGetProcAddress("glCreateShader"))(0x9559);	
	int sf = ((PFNGLCREATESHADERPROC)wglGetProcAddress("glCreateShader"))(0x8B30);	
	((PFNGLSHADERSOURCEPROC)wglGetProcAddress("glShaderSource"))(sm,1,&MS,0);
	((PFNGLSHADERSOURCEPROC)wglGetProcAddress("glShaderSource"))(sf,1,&FS,0);	
	((PFNGLCOMPILESHADERPROC)wglGetProcAddress("glCompileShader"))(sm);
	((PFNGLCOMPILESHADERPROC)wglGetProcAddress("glCompileShader"))(sf);	
	((PFNGLATTACHSHADERPROC)wglGetProcAddress("glAttachShader"))(p,sm);
	((PFNGLATTACHSHADERPROC)wglGetProcAddress("glAttachShader"))(p,sf);	
	((PFNGLLINKPROGRAMPROC)wglGetProcAddress("glLinkProgram"))(p);
	return p;
}

void Rendering()
{
	glDisable(GL_CULL_FACE);
	glDisable(GL_BLEND);
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	glDepthMask(GL_FALSE);
	((PFNGLUSEPROGRAMPROC)wglGetProcAddress("glUseProgram"))(PS);
	((PFNGLDRAWMESHTASKSNVPROC)wglGetProcAddress("glDrawMeshTasksNV"))(0,1);
}

typedef enum UnityGfxRenderer
{
	kUnityGfxRendererNull = 4, 
	kUnityGfxRendererOpenGLCore = 17, 
} UnityGfxRenderer;

typedef enum UnityGfxDeviceEventType
{
	kUnityGfxDeviceEventInitialize = 0,
	kUnityGfxDeviceEventShutdown = 1,
	kUnityGfxDeviceEventBeforeReset = 2,
	kUnityGfxDeviceEventAfterReset = 3,
} UnityGfxDeviceEventType;
	
struct UnityInterfaceGUID
{
	UnityInterfaceGUID(unsigned long long high, unsigned long long low) : m_GUIDHigh(high) , m_GUIDLow(low) { }
	unsigned long long m_GUIDHigh;
	unsigned long long m_GUIDLow;
};

struct IUnityInterface {};
typedef void (__stdcall * IUnityGraphicsDeviceEventCallback)(UnityGfxDeviceEventType eventType);

struct IUnityInterfaces
{
	IUnityInterface* (__stdcall* GetInterface)(UnityInterfaceGUID guid);
	void(__stdcall* RegisterInterface)(UnityInterfaceGUID guid, IUnityInterface * ptr);
	template<typename INTERFACE>
	INTERFACE* Get()
	{
		return static_cast<INTERFACE*>(GetInterface(UnityInterfaceGUID(0x7CBA0A9CA4DDB544ULL, 0x8C5AD4926EB17B11ULL)));
	}
	void Register(IUnityInterface* ptr)
	{
		RegisterInterface(UnityInterfaceGUID(0x7CBA0A9CA4DDB544ULL, 0x8C5AD4926EB17B11ULL), ptr);
	}
};

struct IUnityGraphics : IUnityInterface
{
	void(__stdcall* RegisterDeviceEventCallback)(IUnityGraphicsDeviceEventCallback callback);
};

typedef void (__stdcall* UnityRenderingEvent)(int eventId);
typedef void(__stdcall* UnregisterDeviceEventCallback)(IUnityGraphicsDeviceEventCallback callback);
static UnityGfxRenderer DeviceType = kUnityGfxRendererNull;

static void __stdcall OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType)
{
	if (eventType == kUnityGfxDeviceEventInitialize)
	{
		DeviceType = kUnityGfxRendererOpenGLCore;
		PS = MakeShaders(MeshShader,FragmentShader);
	}
	if (eventType == kUnityGfxDeviceEventShutdown)
	{
		DeviceType = kUnityGfxRendererNull;
	}
}

static void __stdcall OnRenderEvent(int eventID)
{
	Rendering();
}

extern "C" void	__declspec(dllexport) __stdcall UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
	IUnityInterfaces* s_UnityInterfaces = unityInterfaces;
	IUnityGraphics* s_Graphics = s_UnityInterfaces->Get<IUnityGraphics>();
	s_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
	OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}

extern "C" void __declspec(dllexport) __stdcall UnityPluginUnload()
{
	UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);	
}

extern "C" UnityRenderingEvent __declspec(dllexport) __stdcall Execute()
{
	return OnRenderEvent;
}