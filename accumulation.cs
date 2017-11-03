//Assign script to main camera, then bind material with accumulation.shader
//It draws fullscreen quad. Shader output is set as shader input for next frame.
using UnityEngine;
using System.Collections;

public class accumulation : MonoBehaviour 
{
	public Material material;
	
	void OnPostRender()
	{
		GL.PushMatrix();
		material.SetPass(0);
		GL.LoadOrtho();
		GL.Begin(GL.QUADS);
		GL.TexCoord2(0, 0);
		GL.Vertex3(0.0F, 0.0F, 0);
		GL.TexCoord2(0, 1);
		GL.Vertex3(0.0F, 1.0F, 0);
		GL.TexCoord2(1, 1);
		GL.Vertex3(1.0F, 1.0F, 0);
		GL.TexCoord2(1, 0);
		GL.Vertex3(1.0F, 0.0F, 0);
		GL.End();
		GL.PopMatrix();		
		Texture2D buffer = new Texture2D(Screen.width, Screen.height);
		buffer.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
		buffer.Apply();
		material.mainTexture = buffer;
	}
}
