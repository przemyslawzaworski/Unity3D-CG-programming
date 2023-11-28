/*
Resolution = Dilation
256 = 2px
512 = 4px
1024 = 8px
2048 = 16px
4096 = 32 px
8192 = 64 px
*/
using UnityEngine;
 
public class BakeTexture : MonoBehaviour
{
	public Mesh SourceMesh;
	public Shader BakeTextureShader;
	public int Resolution = 2048;
	public float Dilation = 16;
	public Rendering RenderMode = Rendering.DirectX;

	public enum Rendering
	{
		DirectX,
		OpenGL
	}

	void Start()
	{
		if (SourceMesh != null)
		{
			RenderTexture renderTexture = new RenderTexture(Resolution, Resolution, 32, RenderTextureFormat.ARGB32);
			renderTexture.filterMode = FilterMode.Trilinear;
			renderTexture.Create();
			Material material = new Material(BakeTextureShader);
			RenderTexture currentTexture = RenderTexture.active;
			RenderTexture.active = renderTexture;
			GL.Clear(true, true, Color.black, 1.0f);
			material.SetInt("_TextureSize", Resolution);
			material.SetFloat("_Dilation", Dilation);
			material.SetInt("_RenderMode", RenderMode == Rendering.DirectX ? 0 : 1);
			material.SetPass(0);
			Graphics.DrawMeshNow(SourceMesh, Vector3.zero, Quaternion.identity);
			Texture2D texture = new Texture2D(Resolution, Resolution, TextureFormat.ARGB32, false, false);
			texture.ReadPixels( new Rect(0, 0, Resolution, Resolution), 0, 0);
			RenderTexture.active = currentTexture;
			byte[] bytes = texture.EncodeToPNG();
			System.IO.File.WriteAllBytes(System.IO.Path.Combine(Application.dataPath, "Texture.png"), bytes);
			Destroy(material);
			Destroy(texture);
			renderTexture.Release();
		}
	}
}