using UnityEngine;

public class depth : MonoBehaviour 
{
	public Material material;
	public Camera main_camera;
	
	void Start () 
	{
		main_camera.depthTextureMode = DepthTextureMode.Depth;
		main_camera.farClipPlane = 80f; //Draw distance
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Graphics.Blit (source, destination, material);
	}
}
