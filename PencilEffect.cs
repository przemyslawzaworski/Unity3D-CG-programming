using UnityEngine;

// Add script to camera and assign shader
public class PencilEffect : MonoBehaviour 
{
	[Header("Pencil post processing effect")]
	public Shader PencilEffectShader;
	public bool InvertY = true;
	[Range(0.1f, 16.0f)] public float ScaleFactor = 5.0f;
	private Material _Material;

	void Start()
	{
		if (PencilEffectShader == null) PencilEffectShader = Shader.Find("Pencil Effect");
		_Material = new Material(PencilEffectShader);
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
		_Material.SetFloat("_InvertY", System.Convert.ToSingle(InvertY));
		_Material.SetFloat("_ScaleFactor", ScaleFactor);
		Blit (source, destination, _Material);
	}

	void OnDestroy()
	{
		if (_Material != null) Destroy(_Material);
	}
}