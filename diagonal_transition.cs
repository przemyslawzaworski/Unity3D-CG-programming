using UnityEngine;
using System.Collections;

public class diagonal_transition : MonoBehaviour 
{
	public GameObject light;
	public Material material;

	void Update()
	{
		light.transform.Rotate(new Vector3(Time.deltaTime*4.0f,0.0f,0.0f)); 
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Graphics.Blit (source, destination, material);
	}
}