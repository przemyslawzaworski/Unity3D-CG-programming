//Author: Przemyslaw Zaworski
//Add script to GameObject, assign save_render_texture.compute
//and any material with "_MainTex" texture slot to see render texture
//(for example built-in Unlit).
//Press space key to save render texture.
using UnityEngine;
using System.IO;

public class save_render_texture : MonoBehaviour 
{
	public ComputeShader shader;
	public Material material;
	public int resolution;
	RenderTexture render_texture;
	ComputeBuffer compute_buffer;
	float time;
	
	void Start () 
	{
		render_texture = new RenderTexture(resolution,resolution,0);
		render_texture.enableRandomWrite = true;
		render_texture.Create();
		shader.SetTexture(0, "render_texture", render_texture);	
		compute_buffer = new ComputeBuffer(resolution*resolution, sizeof(float)*3, ComputeBufferType.Default);	
		shader.SetBuffer(0, "compute_buffer", compute_buffer);
		shader.SetFloat("time",Time.time);		
	}

	void Update () 
	{
		shader.SetFloat("time",Time.time);
		shader.Dispatch(0, render_texture.width / 8, render_texture.height / 8, 1);
		material.SetTexture("_MainTex",render_texture);		
		if (Input.GetKeyDown(KeyCode.Space))
		{
			Texture2D image = new Texture2D (resolution,resolution, TextureFormat.RGBA32, false);
			Vector3[] pixels = new Vector3[resolution*resolution]; 
			compute_buffer.GetData (pixels); 
			for (int y = 0; y < resolution; y++) 
			{
				for (int x = 0; x <resolution; x++) 
				{ 
					int i = y*resolution+x;
					Color color = new Color (pixels[i].x,pixels[i].y,pixels[i].z, 1.0f);
					image.SetPixel (x, y, color);
				}
			}
			byte[] bytes = image.EncodeToPNG ();
			UnityEngine.Object.Destroy (image);
			File.WriteAllBytes ("C:\\output.png", bytes);			
		}
	}

	void OnDestroy() 
	{
		render_texture.Release();
		compute_buffer.Release();
	}	
}