//Basic template for painting materials in 3D.
//Target game object must have attached mesh collider.

using UnityEngine;

public class paint3D : MonoBehaviour 
{
	public Camera MainCamera;
	public Material material;
	public GameObject target;
	
	void Update () 
	{
		if (!Input.GetMouseButton(0))
			return;
		RaycastHit hit;
		if (!Physics.Raycast(MainCamera.ScreenPointToRay(Input.mousePosition), out hit))
			return;
		if (hit.distance<2.0f && (hit.collider.gameObject.name==target.name))
			material.SetVector("_vector", new Vector4(hit.textureCoord.x,hit.textureCoord.y,0.0f,0.0f));		
	}
}
