using UnityEngine;

public class NurbsHair : MonoBehaviour
{
	public Shader NurbsHairShader;
	public Color HairColor = new Color(1.0f, 0.5f, 0.5f, 1.0f);	
	public Color HairEnds = new Color(0.0f, 0.0f, 0.0f, 1.0f);
	[Range(1.0f, 10.0f)] public float HairPower = 5.0f;	
	[Range(1, 100000)] public int HairCount = 50000;
	[Range(0.0f, 0.5f)] public float HairEffect = 0.0f;	
	[Range(0.1f, 1.0f)] public float HairScale = 0.75f;
	[Range(2, 64)] public int HairQuality = 32;
	[Range(0.0f, 10.0f)] public float HairWind = 0.0f;
	public bool HairShading = true;
	public enum HairMode {NURBSDerivatives = 0, VertexPositions = 1}
	public HairMode HairNormalsCalculation = HairMode.VertexPositions;
	public bool HairDebugNormals = false;
	public Vector4 HairWeights = Vector4.one;
	private Material _Material;

	void Start()
	{
		if (NurbsHairShader == null) NurbsHairShader = Shader.Find("Nurbs Hair");
		_Material = new Material(NurbsHairShader);
	}

	void OnRenderObject() 
	{
		_Material.SetPass(0);
		_Material.SetFloat("_HairScale", HairScale);
		_Material.SetFloat("_HairEffect", HairEffect);
		_Material.SetFloat("_HairPower", HairPower);
		_Material.SetInt("_HairQuality", HairQuality * 2); // must be even number
		_Material.SetColor("_HairColor", HairColor);
		_Material.SetColor("_HairEnds", HairEnds);
		_Material.SetVector("_HairWeights", HairWeights);
		_Material.SetVector("_HairPosition", this.transform.position);
		_Material.SetInt("_HairShading", System.Convert.ToInt32(HairShading));
		_Material.SetFloat("_HairWind", HairWind);
		_Material.SetInt("_HairNormalsMode", (int)HairNormalsCalculation);
		_Material.SetInt("_HairDebugNormals", System.Convert.ToInt32(HairDebugNormals));
		Graphics.DrawProceduralNow(MeshTopology.Lines, HairQuality * HairCount, 1);
	}
}