// Edit -> Project Settings -> Graphics -> Always Included Shader -> ReactionDiffusion
// Add script to quad.

using UnityEngine;

public class ReactionDiffusion : MonoBehaviour 
{
	Material material;
	RenderTexture input, output;
	bool swap = true;
	int frame = 0;
	
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
		GL.Vertex3(1.0f, 1.0f, 1.0f); 
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.invertCulling = false;
		GL.PopMatrix();
	}
	
	void OnEnable () 
	{
		material = new Material(Shader.Find("ReactionDiffusion"));
		input = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32);		
		output = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32);		
		GetComponent<Renderer>().material = material;
	}
	
	void Update () 
	{
		material.SetInt("iFrame",frame);
		if (swap)
		{
			material.SetTexture("_MainTex", input);
			Blit(input,output,material);
			material.SetTexture("_Buffer", output);
		}
		else
		{
			material.SetTexture("_MainTex", output);
			Blit(output,input,material);
			material.SetTexture("_Buffer", input);
		}
		swap = !swap;
		frame++;
	}
	
	void OnDestroy ()
	{
		input.Release();
		output.Release();
	}
}