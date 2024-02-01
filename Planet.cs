using UnityEngine;

public class Planet : MonoBehaviour
{
	[SerializeField] private Shader _Shader;
	[SerializeField] private Camera _Camera;
	[System.NonSerialized] private Material _Material;

	void Start()
	{
		_Material = new Material(_Shader);
	}

	Matrix4x4 GetFrustumCorners(Camera camera)
	{
		float tangent = Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
		Vector3 right = Vector3.right * tangent * camera.aspect;
		Vector3 up = Vector3.up * tangent;
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		frustumCorners.SetRow(0, (-Vector3.forward - right + up));
		frustumCorners.SetRow(1, (-Vector3.forward + right + up));
		frustumCorners.SetRow(2, (-Vector3.forward + right - up));
		frustumCorners.SetRow(3, (-Vector3.forward - right - up));
		return frustumCorners;
	}

	void Blit(RenderTexture source, RenderTexture destination, Material material)
	{
		RenderTexture.active = destination;
		material.SetTexture("_MainTex", source);
		GL.PushMatrix();
		GL.LoadOrtho(); 
		material.SetPass(0);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord3(0, 0.0f, 0.0f, 3.0f);
		GL.Vertex3(0.0f, 0.0f, 0.0f);
		GL.MultiTexCoord3(0, 1.0f, 0.0f, 2.0f);
		GL.Vertex3(1.0f, 0.0f, 0.0f);
		GL.MultiTexCoord3(0, 1.0f, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 0.0f);
		GL.MultiTexCoord3(0, 0.0f, 1.0f, 0.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.PopMatrix();
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		_Material.SetMatrix("_FrustumCorners", GetFrustumCorners(_Camera));
		_Material.SetMatrix("_CameraToWorldMatrix", _Camera.cameraToWorldMatrix);
		Blit(source, destination, _Material);
	}

	void OnDestroy()
	{
		Destroy(_Material);
	}
}