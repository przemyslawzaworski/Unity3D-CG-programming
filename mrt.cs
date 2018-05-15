using UnityEngine;

public class mrt : MonoBehaviour 
{
	public RenderTexture[] RenderTextures;
	public Material material;

	void MRT (RenderTexture[] rt, Material mat, int pass = 0)
	{
		RenderBuffer[] rb = new RenderBuffer[rt.Length];
		for(int i = 0; i < rt.Length; i++) rb[i] = rt[i].colorBuffer;
		Graphics.SetRenderTarget(rb, rt[0].depthBuffer);
		GL.Clear(true, true, Color.clear);
		GL.PushMatrix();
		GL.LoadOrtho();
		mat.SetPass(pass);
		GL.Begin(GL.QUADS);
		GL.Vertex3(0.0f, 0.0f, 0.1f);
		GL.TexCoord2(0.0f, 0.0f); 
		GL.Vertex3(1.0f, 0.0f, 0.1f);
		GL.TexCoord2(1.0f, 0.0f); 
		GL.Vertex3(1.0f, 1.0f, 0.1f);
		GL.TexCoord2(1.0f, 1.0f); 
		GL.Vertex3(0.0f, 1.0f, 0.1f);
		GL.TexCoord2(0.0f, 1.0f); 
		GL.End();
		GL.PopMatrix();
	}

	void Update () 
	{
		MRT(RenderTextures,material,0);
	}
}
