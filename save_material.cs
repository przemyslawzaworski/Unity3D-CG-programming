//Author: Przemyslaw Zaworski

using UnityEngine;
using System.Diagnostics;

public class save_material : MonoBehaviour 
{
	[Tooltip("Assign save_material.compute")]
	public ComputeShader InternalShader;
	[Tooltip("Assign source material")]	
	public Material SourceMaterial;	
	[Tooltip("Set output image resolution")]	
	public int resolution;
	[Tooltip("Set output path, for example C:\\output.png")]	
	public string path;
	[Tooltip("Pass blending ?")]	
	public bool blend;	
	[Tooltip("Set source material pass (-1 for all)")]	
	public int pass;
	[Tooltip("Gamma or linear space ?")]	
	public bool gamma;
	[Range(-0.5f,0.5f)]
	public float brightness;
	CustomRenderTexture render_texture;
	ComputeBuffer compute_buffer;
	
	void Start () 
	{
		render_texture = new CustomRenderTexture(resolution,resolution,0);
		render_texture.enableRandomWrite = true;
		render_texture.Create();
		render_texture.updateMode = CustomRenderTextureUpdateMode.Realtime;
		render_texture.initializationMode = CustomRenderTextureUpdateMode.Realtime;		
		render_texture.initializationMaterial = SourceMaterial;
		render_texture.initializationSource = CustomRenderTextureInitializationSource.Material;
		render_texture.material = new Material(Shader.Find("Unlit/Texture"));	
		InternalShader.SetTexture(0, "render_texture", render_texture);	
		compute_buffer = new ComputeBuffer(resolution*resolution, sizeof(float)*3, ComputeBufferType.Default);	
		InternalShader.SetBuffer(0, "compute_buffer", compute_buffer);
		InternalShader.SetFloat("brightness", brightness);
		if (gamma)
			InternalShader.SetFloat("color_space", 0.4545f);
		else
			InternalShader.SetFloat("color_space", 1.0f);			
	}

	public void GenerateImage ()
	{
		float start = Time.realtimeSinceStartup;
		RenderTexture s, temporary;
		if (blend)
		{
			s = new RenderTexture (resolution,resolution,0);
			temporary = new RenderTexture (resolution,resolution,0);
			for (int i=0;i<pass;i++)
			{
				Graphics.Blit(s,temporary,SourceMaterial,i);
				Graphics.Blit(temporary,s,SourceMaterial,i);
			}
			InternalShader.SetTexture(0, "render_texture", temporary);
			InternalShader.Dispatch(0, render_texture.width / 8, render_texture.height / 8, 1);
		}
		else
		{
			s = new RenderTexture (resolution,resolution,0);
			temporary = new RenderTexture (resolution,resolution,0);
			Graphics.Blit(s,temporary,SourceMaterial,pass);
			InternalShader.SetTexture(0, "render_texture", temporary);
			InternalShader.Dispatch(0, render_texture.width / 8, render_texture.height / 8, 1);			
		}
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
		System.IO.File.WriteAllBytes (path, bytes);
		float end = Time.realtimeSinceStartup - start;
		Process process = new Process();
		ProcessStartInfo info = new ProcessStartInfo();
		info.UseShellExecute = true;
		info.FileName = path;
		process.StartInfo = info;
		process.Start();
		UnityEngine.Debug.Log ("Image saved in "+System.String.Format( "{0:0.000000}",end)+"  seconds.");		
	}

	public void ResetBuffer ()
	{
		OnDestroy();
		Start();
	}
	
	void Update () 
	{
		InternalShader.SetFloat("brightness", brightness);
		if (gamma)
			InternalShader.SetFloat("color_space", 0.4545f);
		else
			InternalShader.SetFloat("color_space", 1.0f);		
		InternalShader.Dispatch(0, render_texture.width / 8, render_texture.height / 8, 1);		
	}

	void OnDestroy() 
	{
		render_texture.Release();
		compute_buffer.Release();
	}	
}