/*
Very simple shadow mapping post processing effect.
In Unity Editor:
- Create New Scene;
- Add ShadowMapping component to Main Camera
- Assign "ShadowMapping" shader
- Add "3D Object/Sphere" to the hierarchy window and assign as Light in ShadowMapping component
- Add some geometry to the scene (for example terrain component)
- Play (shadows will be only visible in Game View)
- Light object now has added light camera component. Change light camera properties to change field of view etc. In scene view, see light camera frustum.
- Play with Shadow Bias parameter
*/

using UnityEngine;

public class ShadowMapping : MonoBehaviour
{
	public Shader ShadowMappingShader;
	public GameObject Light;
	[Range(0.0f, 5.0f)] public float ShadowBias = 1.0f;
	public bool InvertY = true;

	private Camera _LightCamera;
	private Camera _MainCamera;	
	private Material _Material;
	private RenderTexture _RenderTexture;

	void Start()
	{
		_LightCamera = Light.AddComponent<Camera>();
		_LightCamera.renderingPath = RenderingPath.DeferredShading;
		_MainCamera = this.gameObject.GetComponent<Camera>();
		_MainCamera.depthTextureMode = _LightCamera.depthTextureMode = DepthTextureMode.Depth;
		_Material = new Material(ShadowMappingShader);
		_RenderTexture = new RenderTexture(4096, 4096, 32, RenderTextureFormat.Depth);
		_RenderTexture.Create();
		_LightCamera.targetTexture = _RenderTexture;
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		_LightCamera.Render();
		Matrix4x4 lightViewProjection = GL.GetGPUProjectionMatrix(_LightCamera.projectionMatrix, true) * _LightCamera.worldToCameraMatrix;
		_Material.SetMatrix("_LightViewProjection", lightViewProjection);
		_Material.SetFloat("_ShadowBias", ShadowBias);
		_Material.SetFloat("_InvertY", System.Convert.ToSingle(InvertY));
		Matrix4x4 m = GL.GetGPUProjectionMatrix(_MainCamera.projectionMatrix, false);
		m[2, 3] = m[3, 2] = 0.0f; m[3, 3] = 1.0f;
		Matrix4x4 projectionToWorld = Matrix4x4.Inverse(m * _MainCamera.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -m[2,2]), Quaternion.identity, Vector3.one);
		_Material.SetMatrix("_ProjectionToWorld", projectionToWorld);
		Graphics.Blit (source, destination, _Material);
	}	

	void OnDestroy()
	{
		_RenderTexture.Release();
		Destroy(_Material);
	}
}