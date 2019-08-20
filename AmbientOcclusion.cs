using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AmbientOcclusion : MonoBehaviour 
{
	public Shader SSAO;
	[Range(0, 1)] public float Radius = 0.5f;
	[Range(0, 1)] public float Bias = 0.3f;
	[Range(0, 5)] public float Intensity = 1.0f;
	[Range(0, 5)] public float Blur = 1.0f;   
	[Range(1, 128)] public int SampleCount = 64;
	public bool Debug = false;

	private Material material;
	private List<Vector4> kernel;
	private int count = -1;

	void Awake() 
	{
		material = new Material(SSAO);
		kernel = new List<Vector4>(SampleCount);
	}

	void GenerateKernel() 
	{
		count = SampleCount;
		for (int i = 0; i < SampleCount; i++) kernel.Add(UnityEngine.Random.insideUnitSphere);
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) 
	{
		if (count != SampleCount || kernel.Count != SampleCount) GenerateKernel();
		Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;
		material.SetVectorArray("Kernel", kernel);
		material.SetFloat("SampleCount", count);           
		material.SetFloat("Debug", Debug ? 1.0f : 0.0f);
		material.SetFloat("Radius", Radius);
		material.SetFloat("Bias", Bias);
		material.SetFloat("Intensity", Intensity);
		var RTA = RenderTexture.GetTemporary(Screen.width, Screen.height);
		var RTB = RenderTexture.GetTemporary(Screen.width, Screen.height);
		Graphics.Blit(source, RTA, material, 0);
		material.SetFloat("BlurOffset", Blur);
		Graphics.Blit(RTA, RTB, material, 1);
		Graphics.Blit(RTB, RTA, material, 1);
		Graphics.Blit(RTA, RTB, material, 1);
		Graphics.Blit(RTB, RTA, material, 1);
		material.SetTexture("OcclusionMap", RTA);
		Graphics.Blit(source, destination, material, 2);
		RenderTexture.ReleaseTemporary(RTA);
		RenderTexture.ReleaseTemporary(RTB);
	}
}