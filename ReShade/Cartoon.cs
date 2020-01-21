using UnityEngine;
using System.Collections;

public class Cartoon : MonoBehaviour 
{
	public Shader CartoonShader;
	public Camera MainCamera;
	
	[Range(0.1f, 10.0f)] public float Power = 1.5f;
	[Range(0.1f, 6.0f)]  public float EdgeSlope = 1.5f;

	Material _Material;

	void Blit(RenderTexture source, RenderTexture destination, Material mat, int pass, string name)
	{
		RenderTexture.active = destination;
		mat.SetTexture(name, source);
		GL.PushMatrix();
		GL.LoadOrtho();
		GL.invertCulling = true;
		mat.SetPass(pass);
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
	
	void Start () 
	{
		_Material = new Material(CartoonShader);
	}	
	
	void Update ()
	{		
		_Material.SetFloat("Power", Power);
		_Material.SetFloat("EdgeSlope", EdgeSlope);
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Blit (source, destination, _Material, 0, "BackBuffer");
	}
}