// Set DirectX 12 and Linear Color Space. Add script to camera and assign variables. Play (tested with Unity 2019.4.4f1 (64-bit)).
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class PathTracing : MonoBehaviour
{
	public Color AmbientColor = Color.white;
	public RayTracingShader PathTracingShader;  //PathTracing.raytrace
	public Shader IndirectDiffuseShader;  //IndirectDiffuse.shader
	public Shader ProgressiveShader;  //ProgressiveRendering.shader

	private Camera _Camera;
	private Material _Material;
	private Matrix4x4 _ModelMatrix;
	private RayTracingAccelerationStructure _AccelerationStructure;
	private RenderTexture _RenderTarget0;
	private RenderTexture _RenderTarget1;
	private RenderTexture _RenderTarget2;
	private int _Frame;

	void Start()
	{
		if (!SystemInfo.supportsRayTracing) Debug.Log("Ray Tracing not supported !");
		_Camera = GetComponent<Camera>();
		_RenderTarget0 = new RenderTexture(_Camera.pixelWidth, _Camera.pixelHeight, 0, RenderTextureFormat.ARGBFloat);
		_RenderTarget0.enableRandomWrite = true;
		_RenderTarget0.Create();
		_RenderTarget1 = new RenderTexture(_RenderTarget0);
		_RenderTarget2 = new RenderTexture(_RenderTarget0);
		RayTracingAccelerationStructure.RASSettings settings = new RayTracingAccelerationStructure.RASSettings();
		settings.layerMask = ~0;
		settings.managementMode = RayTracingAccelerationStructure.ManagementMode.Automatic;
		settings.rayTracingModeMask = RayTracingAccelerationStructure.RayTracingModeMask.Everything;
		_AccelerationStructure = new RayTracingAccelerationStructure(settings);
		Renderer[] renderers = FindObjectsOfType<Renderer>();
		for(int i = 0; i < renderers.Length; i++)
		{
			Material[] materials = renderers[i].sharedMaterials;
			for (int j = 0; j < materials.Length; j++) materials[j] = new Material(IndirectDiffuseShader);
			renderers[i].sharedMaterials = materials;
			_AccelerationStructure.AddInstance(renderers[i]);
		}
		_AccelerationStructure.Build();
		PathTracingShader.SetAccelerationStructure("_AccelerationStructure", _AccelerationStructure);
		PathTracingShader.SetTexture("_RenderTarget", _RenderTarget0);
		PathTracingShader.SetShaderPass("PathTracingRTX");
		_Material = new Material(ProgressiveShader);
		Reset();
	}

	void Reset()
	{
		_AccelerationStructure.Update();
		PathTracingShader.SetVector("_AmbientColor", AmbientColor.gamma);
		Matrix4x4 frustum = Matrix4x4.identity;
		frustum.SetRow(0, _Camera.ViewportToWorldPoint(new Vector3(0, 1, _Camera.farClipPlane)).normalized);
		frustum.SetRow(1, _Camera.ViewportToWorldPoint(new Vector3(1, 1, _Camera.farClipPlane)).normalized);
		frustum.SetRow(2, _Camera.ViewportToWorldPoint(new Vector3(0, 0, _Camera.farClipPlane)).normalized);
		frustum.SetRow(3, _Camera.ViewportToWorldPoint(new Vector3(1, 0, _Camera.farClipPlane)).normalized);
		PathTracingShader.SetMatrix("_Frustum", frustum);
		PathTracingShader.SetVector("_WorldSpaceCameraPos", _Camera.transform.position);
		_ModelMatrix = _Camera.transform.localToWorldMatrix;
		_Frame = 0;
	}

	void Update()
	{
		if(_ModelMatrix != _Camera.transform.localToWorldMatrix) Reset();	
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		PathTracingShader.SetInt("_Frame", _Frame);
		PathTracingShader.Dispatch("RayGenerationShader", _Camera.pixelWidth, _Camera.pixelHeight, 1, _Camera);
		_Material.SetTexture("_MainImage", _RenderTarget0);
		_Material.SetTexture("_Accumulation", _RenderTarget1);
		_Material.SetInt("_Frame", _Frame++);
		Graphics.Blit(_RenderTarget0, _RenderTarget2, _Material);
		Graphics.Blit(_RenderTarget2, destination);
		var target = _RenderTarget1;
		_RenderTarget1 = _RenderTarget2;
		_RenderTarget2 = target;
	}

	void OnDestroy()
	{
		_AccelerationStructure.Release();
		_RenderTarget0.Release();
		_RenderTarget1.Release();
		_RenderTarget2.Release();
		Resources.UnloadUnusedAssets();
	}
}