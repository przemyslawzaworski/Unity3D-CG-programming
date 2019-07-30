using UnityEngine;

public class DrawSphere : MonoBehaviour
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
		Graphics.DrawProcedural(MeshTopology.Triangles, 12288, 1);
	}
}
