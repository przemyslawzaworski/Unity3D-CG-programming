// Add script to Main Camera. Volume spot light will be rendered in world position (0,0,0).
// Script will be improved in future.

using UnityEngine;

public class VolumeSpotLight: MonoBehaviour
{
	public Shader VolumeLightShader;
	Material _Material;
	Camera _Camera;
		
	private Matrix4x4 GetFrustumCorners(Camera cam)
	{
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		float fovWHalf = cam.fieldOfView * 0.5f;
		float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
		Vector3 toRight = Vector3.right * tan_fov * cam.aspect;
		Vector3 toTop = Vector3.up * tan_fov;
		Vector3 topLeft = (-Vector3.forward - toRight + toTop);
		Vector3 topRight = (-Vector3.forward + toRight + toTop);
		Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
		Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);
		frustumCorners.SetRow(0, topLeft);
		frustumCorners.SetRow(1, topRight);
		frustumCorners.SetRow(2, bottomRight);
		frustumCorners.SetRow(3, bottomLeft);
		return frustumCorners;
	} 

	void Blit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
	{
		RenderTexture.active = dest;
		fxMaterial.SetTexture("_MainTex", source);
		GL.PushMatrix();
		GL.LoadOrtho(); 
		fxMaterial.SetPass(passNr);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 3.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 2.0f);
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 1.0f);
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);       
		GL.End();
		GL.PopMatrix();
	}
	
	void Start ()
	{
		_Camera = Camera.main;
		_Material = new Material(VolumeLightShader);
	}
	
	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		_Material.SetMatrix("_FrustumCornersES", GetFrustumCorners(_Camera));
		_Material.SetMatrix("_CameraInvViewMatrix", _Camera.cameraToWorldMatrix);
		_Material.SetVector("_CameraWS", _Camera.transform.position);
		Blit(source, destination, _Material, 0);
	}

}