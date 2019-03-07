// Add script to quad and assign material with shader. Play.

using UnityEngine;

public class NoiseTexture : MonoBehaviour 
{
	public Material material;
	RenderTexture RT;
	int property;
	
	void Blit(RenderTexture destination, Material mat)
	{
		RenderTexture.active = destination;
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
			
	void Start () 
	{
		RT = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGBFloat);
		RT.filterMode = FilterMode.Point;			
		GetComponent<Renderer>().material = material;
		property = Shader.PropertyToID("_BufferA");
	}
	
	void Update () 
	{
		Blit(RT, material);
		material.SetTexture(property, RT);
	}
	
	void OnDestroy ()
	{
		RT.Release();		
	}
}