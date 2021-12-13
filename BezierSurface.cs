using UnityEngine;

public class BezierSurface : MonoBehaviour
{
	public Shader BezierSurfaceShader;
	[Range(1, 1024)] public int TessellationFactor = 32;
	private Material _Material;

	void Start()
	{
		if (BezierSurfaceShader == null) BezierSurfaceShader = Shader.Find("Bezier Surface");
		_Material = new Material(BezierSurfaceShader);
	}

	void OnRenderObject() 
	{
		_Material.SetInt("_TessellationFactor", TessellationFactor);
		_Material.SetPass(0);
		int vertexCount = TessellationFactor * TessellationFactor * 6;
		Graphics.DrawProcedural(MeshTopology.Triangles, vertexCount, 1);
	}
}