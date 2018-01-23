using UnityEngine;

public class debug_vertex_index : MonoBehaviour 
{
	public Material material;
	public GameObject gameobject;

	void Start () 
	{
		Mesh mesh = gameobject.GetComponent<MeshFilter>().sharedMesh;
		material.SetInt("amount",(int)mesh.vertices.Length);	
	}
}
