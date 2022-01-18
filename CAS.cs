using UnityEngine;

// Add script to camera and assign Hidden/CAS shader
public class CAS : MonoBehaviour 
{
	[Header("Contrast Adaptive Sharpening post processing effect")]
	public Shader ContrastAdaptiveSharpeningShader;
	[Range(0.0f, 1.0f)] public float Amount = 0.2f;
	[Range(0.0f, 5.0f)] public float Radius = 1.0f;
	public bool InvertY = false;
	private Material _Material;

	void Start()
	{
		if (ContrastAdaptiveSharpeningShader == null) ContrastAdaptiveSharpeningShader = Shader.Find("Hidden/CAS");
		_Material = new Material(ContrastAdaptiveSharpeningShader);
	}

	void Blit(RenderTexture source, RenderTexture destination, Material mat)
	{
		RenderTexture.active = destination;
		mat.SetTexture("_MainTex", source);
		GL.PushMatrix();
		GL.LoadOrtho();
		GL.invertCulling = true;
		mat.SetPass(0);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 0.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 0.0f); 
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 0.0f); 
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.invertCulling = false;
		GL.PopMatrix();
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		_Material.SetFloat("_Amount", Amount);
		_Material.SetFloat("_Radius", Radius);
		_Material.SetFloat("_InvertY", System.Convert.ToSingle(InvertY));
		Blit (source, destination, _Material);
	}

	void OnDestroy()
	{
		if (_Material != null) Destroy(_Material);
	}
}