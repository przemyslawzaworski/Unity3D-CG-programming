//Apply directly to Main Camera.
using UnityEngine;

public class fire : MonoBehaviour 
{
	public Material material;

	void Update()
	{
		float  x = transform.eulerAngles.x * Mathf.Deg2Rad;
		float  y = transform.eulerAngles.y * Mathf.Deg2Rad;
		float  z = transform.eulerAngles.z * Mathf.Deg2Rad;
		Vector4 angle = new Vector4 (-x,-y,-z,1.0f);
		material.SetVector("camera",angle);
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Graphics.Blit (source, destination, material);
	}
}