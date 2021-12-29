using UnityEngine;

public class NurbsSurface : MonoBehaviour
{
	public Shader NurbsSurfaceShader;
	[Range(1, 1024)] public int TessellationFactor = 64;
	private Material _Material;

	void Start()
	{
		if (NurbsSurfaceShader == null) NurbsSurfaceShader = Shader.Find("Nurbs Surface");
		_Material = new Material(NurbsSurfaceShader);
	}

	void OnRenderObject()
	{
		_Material.SetInt("_TessellationFactor", TessellationFactor);
		_Material.SetPass(0);
		int vertexCount = TessellationFactor * TessellationFactor * 6;
		Graphics.DrawProceduralNow(MeshTopology.Triangles, vertexCount, 1);
	}
}