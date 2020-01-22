using UnityEngine;
using System.Collections;

public class PPFX_SSDO : MonoBehaviour 
{
	public Shader PPFXSSDOShader;
	public Camera MainCamera;
	
	[Range(0.001f, 20.0f)] public float pSSDOIntensity = 1.5f; 
	[Range(0.01f, 10.0f)] public float pSSDOAmount = 1.5f;
	[Range(0.0f, 1.0f)] public float pSSDOBounceMultiplier = 0.8f;
	[Range(0.1f, 2.0f)] public float pSSDOBounceSaturation = 1.0f; 
	[Range(1, 256)]  public int pSSDOSampleAmount = 10;
	[Range(4.0f, 1000.0f)] public float pSSDOSampleRange = 70.0f;	
	[Range(0, 3)]  public int pSSDOSourceLOD = 2;
	[Range(0, 3)]  public int pSSDOBounceLOD = 3;
	[Range(2.0f, 100.0f)] public float pSSDOFilterRadius = 8.0f;	
	[Range(0.01f, 0.5f)] public float pSSDOAngleThreshold = 0.125f;	
	[Range(0.01f, 0.95f)] public float pSSDOFadeStart = 0.9f;	
	[Range(0.15f, 1.0f)] public float pSSDOFadeEnd = 0.95f;	
	[Range(0, 1)]  public int pSSDODebugMode = 0;
	
	Material _Material;
	RenderTexture SamplerColorLOD, SamplerViewSpace, SamplerSSDOA, SamplerSSDOB, SamplerSSDOC;

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
		_Material = new Material(PPFXSSDOShader);
		MainCamera.depthTextureMode = DepthTextureMode.Depth;
		SamplerColorLOD = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
		SamplerColorLOD.useMipMap = true;
		SamplerViewSpace = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
		SamplerViewSpace.useMipMap = true;
		SamplerSSDOA = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
		SamplerSSDOB = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
		SamplerSSDOC = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);		
	}	
	
	void Update ()
	{
		_Material.SetFloat("pSSDOIntensity", pSSDOIntensity);
		_Material.SetFloat("pSSDOAmount", pSSDOAmount);
		_Material.SetFloat("pSSDOBounceMultiplier", pSSDOBounceMultiplier);
		_Material.SetFloat("pSSDOBounceSaturation", pSSDOBounceSaturation);
		_Material.SetInt("pSSDOSampleAmount", pSSDOSampleAmount);		
		_Material.SetFloat("pSSDOSampleRange", pSSDOSampleRange);
		_Material.SetInt("pSSDOSourceLOD", pSSDOSourceLOD);
		_Material.SetInt("pSSDOBounceLOD", pSSDOBounceLOD);		
		_Material.SetFloat("pSSDOFilterRadius", pSSDOFilterRadius);
		_Material.SetFloat("pSSDOAngleThreshold",  pSSDOAngleThreshold);
		_Material.SetFloat("pSSDOFadeStart", pSSDOFadeStart);
		_Material.SetFloat("pSSDOFadeEnd", pSSDOFadeEnd);
		_Material.SetInt("pSSDODebugMode", pSSDODebugMode);		
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Blit (source, SamplerColorLOD, _Material, 0, "BackBuffer");
		Blit (SamplerColorLOD, SamplerViewSpace, _Material, 1, "SamplerColorLOD");
		Blit (SamplerViewSpace, SamplerSSDOA, _Material, 2, "SamplerViewSpace");
		Blit (SamplerSSDOA, SamplerSSDOB, _Material, 3, "SamplerSSDOA");
		Blit (SamplerSSDOB, SamplerSSDOC, _Material, 4, "SamplerSSDOB");
		Blit (SamplerSSDOC, SamplerSSDOB, _Material, 5, "SamplerSSDOC");
		Blit (SamplerSSDOB, destination, _Material, 6, "SamplerSSDOB");
	}
}