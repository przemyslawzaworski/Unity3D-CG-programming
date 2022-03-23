using UnityEngine;
 
public class ProceduralSphereTessellation : MonoBehaviour
{
	public Shader ProceduralSphereTessellationShader;
	[Range(0f, 10f)] public float Radius = 2.0f;
	[Range(1, 256)] public int TessellationFactor = 64;
	private Material _Material;

	void Start()
	{
		_Material = new Material(ProceduralSphereTessellationShader);
	}

	void OnRenderObject()
	{
		_Material.SetPass(0);
		_Material.SetFloat("_Radius", Radius);
		_Material.SetFloat("_TessellationFactor", TessellationFactor);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, TessellationFactor * TessellationFactor * 6, 1);
	}

	void OnDestroy()
	{
		Destroy(_Material);
	}
}