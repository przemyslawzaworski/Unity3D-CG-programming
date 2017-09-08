//Assign paint script to Main Camera. Then set material with paint.shader
using UnityEngine;

[ExecuteInEditMode]
public class paint : MonoBehaviour 
{
	public Material material;
	Vector4 iMouse;

	void Update () 
	{
		if (Input.GetMouseButton(0))
		{
			iMouse = new Vector4 (Input.mousePosition.x/Screen.width,1.0f-Input.mousePosition.y/Screen.height,-1.0f,-1.0f) ; 
			material.SetVector("iMouse",iMouse);
		}
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Graphics.Blit (source, destination, material);
	}
}
