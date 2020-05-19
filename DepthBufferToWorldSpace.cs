using UnityEngine;

public class DepthBufferToWorldSpace : MonoBehaviour
{
	public Shader DepthBufferToWorldSpaceShader;

	private Camera _MainCamera;	
	private Material _Material;

	void Start()
	{
		_Material = new Material(DepthBufferToWorldSpaceShader);
		_MainCamera = GetComponent<Camera>();
		_MainCamera.depthTextureMode = DepthTextureMode.Depth;
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Matrix4x4 m = GL.GetGPUProjectionMatrix(_MainCamera.projectionMatrix, false);
		m[2, 3] = m[3, 2] = 0.0f; m[3, 3] = 1.0f;
		Matrix4x4 ProjectionToWorld = Matrix4x4.Inverse(m * _MainCamera.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -m[2,2]), Quaternion.identity, Vector3.one);
		_Material.SetMatrix("unity_ProjectionToWorld", ProjectionToWorld);
		Graphics.Blit (source, destination, _Material);
	}
}
