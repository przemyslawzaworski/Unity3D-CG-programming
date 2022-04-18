using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class FurTextureGenerator : MonoBehaviour
{
	[Header("Press Play, then change parameters in material.")]
	public Shader FurTextureGeneratorShader;
	public int Resolution = 1024;

	private Material _Material;
	private RenderTexture _RenderTexture, _Target;

	void RenderToTexture (RenderTexture destination, Material mat, int pass)
	{
		RenderTexture.active = destination;
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

	void Start()
	{
		if (FurTextureGeneratorShader == null) FurTextureGeneratorShader = Shader.Find("Fur Texture Generator");
		_Material = new Material(FurTextureGeneratorShader);
		_RenderTexture = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGB32);
		_Target = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGB32);
		GetComponent<Renderer>().material = _Material;
	}

	void Export(RenderTexture renderTexture)
	{
		RenderTexture currentTexture = RenderTexture.active;
		RenderTexture.active = renderTexture;
		Texture2D texture = new Texture2D(Resolution, Resolution, TextureFormat.ARGB32, false);
		texture.ReadPixels( new Rect(0, 0, Resolution, Resolution), 0, 0);
		RenderTexture.active = currentTexture;
		byte[] bytes = texture.EncodeToPNG();
		string fileName = "Fur" + Random.Range(0, 1e9f).ToString("F0") + ".png";
		string path = System.IO.Path.Combine(Application.dataPath, fileName);
		System.IO.File.WriteAllBytes(path, bytes);
		System.Diagnostics.Process.Start(path);
	}

	void Update()
	{
		RenderToTexture(_RenderTexture, _Material, 0);
		_Material.SetTexture("_RenderTexture", _RenderTexture);
		RenderToTexture(_Target, _Material, 1);
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_RenderTexture.Release();
		_Target.Release();
	}

	public void ExportNow()
	{
		Export(_Target);
	}
}

#if UNITY_EDITOR
[CustomEditor(typeof(FurTextureGenerator))]
public class FurTextureGeneratorEditor : Editor
{
	public override void OnInspectorGUI()
	{
		DrawDefaultInspector();    
		FurTextureGenerator ftg = (FurTextureGenerator)target;
		if(GUILayout.Button("Export To PNG")) ftg.ExportNow();
	}
}
#endif