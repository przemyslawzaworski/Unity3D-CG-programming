//based on https://github.com/Flafla2/Generic-Raymarch-Unity
using UnityEngine;

public class ocean : MonoBehaviour
{
	public Material material;
	public Camera main_camera ;
		
	private Matrix4x4 GetFrustumCorners(Camera cam)
	{
		float camFov = cam.fieldOfView;
		float camAspect = cam.aspect;
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		float fovWHalf = camFov * 0.5f;
		float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);
		Vector3 toRight = Vector3.right * tan_fov * camAspect;
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

	static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
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
	
	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		material.SetMatrix("_FrustumCornersES", GetFrustumCorners(main_camera));
		material.SetMatrix("_CameraInvViewMatrix", main_camera.cameraToWorldMatrix);
		material.SetVector("_CameraWS", main_camera.transform.position);
		CustomGraphicsBlit(source, destination, material, 0);
	}

}