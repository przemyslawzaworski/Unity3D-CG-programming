using UnityEngine;

public class DrawCubes : MonoBehaviour
{
	public Shader shader;
	protected Material material;
	
	void Start()
	{
		material = new Material(shader);
	}

	void OnRenderObject() 
	{
		material.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Triangles, 36 * 100000, 1);
	}
}