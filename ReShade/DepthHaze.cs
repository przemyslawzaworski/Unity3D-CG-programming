using UnityEngine;
using System.Collections;

public class DepthHaze : MonoBehaviour 
{
	public Shader DepthHazeShader;
	public Camera MainCamera;
	
	[Range(0.0f, 1.0f)] public float EffectStrength = 0.9f; 
	public Color FogColor = new Color(0.8f, 0.8f, 0.8f, 1.0f);
	[Range(0.0f, 1.0f)] public float FogStart = 0.2f;
	[Range(0.0f, 1.0f)] public float FogFactor = 0.2f;

	Material _Material;
	RenderTexture Otis_FragmentBuffer1, Otis_FragmentBuffer2;

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
		_Material = new Material(DepthHazeShader);
		MainCamera.depthTextureMode = DepthTextureMode.Depth;
		Otis_FragmentBuffer1 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
		Otis_FragmentBuffer2 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
	}	
	
	void Update ()
	{
		_Material.SetFloat("EffectStrength", EffectStrength);
		_Material.SetColor("FogColor", FogColor);		
		_Material.SetFloat("FogStart", FogStart);
		_Material.SetFloat("FogFactor", FogFactor);
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Blit (source, Otis_FragmentBuffer1, _Material, 0, "BackBuffer");
		Blit (Otis_FragmentBuffer1, Otis_FragmentBuffer2, _Material, 1, "Otis_SamplerFragmentBuffer1");
		Blit (Otis_FragmentBuffer2, destination, _Material, 2, "Otis_SamplerFragmentBuffer2");
	}
}