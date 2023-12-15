using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderToTextureURP : MonoBehaviour
{
	public Rendering RenderMode = Rendering.DirectX;
	[Range(1.0f, 2.0f)] public float Contrast = 1.0f;
	[Range(0.0f, 1.0f)] public float Radius = 1.0f;
	[SerializeField] private GameObject _GameObject;
	[SerializeField] private Shader _Shader;
	[SerializeField] private Texture _Source;
	private Material _Material;
	private Mesh _Mesh;
	private RenderTexture _Destination;

	public enum Rendering {DirectX, OpenGL}

	Mesh GenerateQuad()
	{
		Mesh mesh = new Mesh();
		Vector3[] vertices = new Vector3[4]
		{
			new Vector3(-1f, -1f, 0f),
			new Vector3( 1f, -1f, 0f),
			new Vector3(-1f,  1f, 0f),
			new Vector3( 1f,  1f, 0f),
		};
		mesh.vertices = vertices;
		int[] triangles = new int[6] {0, 3, 1, 3, 0, 2};
		mesh.triangles = triangles;	
		Vector2[] uv = new Vector2[4]
		{
			new Vector2(0f, 0f),
			new Vector2(1f, 0f),
			new Vector2(0f, 1f),
			new Vector2(1f, 1f)
		};
		mesh.uv = uv;
		return mesh;
	}

	void RenderToTexture (Texture source, RenderTexture destination, Mesh mesh, Material material, string name)
	{
		material.SetTexture(name, source);
		RenderTexture renderTexture = RenderTexture.active;
		RenderTexture.active = destination;
		material.SetPass(0);
		Graphics.DrawMeshNow(mesh, Vector3.zero, Quaternion.identity);
		RenderTexture.active = renderTexture;
	}

	void Start()
	{
		_Material = new Material(_Shader);
		_Mesh = GenerateQuad();
		_Destination = new RenderTexture(_Source.width, _Source.height, 0, RenderTextureFormat.ARGB32);
		_GameObject.GetComponent<MeshRenderer>().material.mainTexture = _Destination;
	}

	void Update()
	{
		Shader.SetGlobalFloat("_BokehContrast", Contrast);
		Shader.SetGlobalFloat("_BokehRadius", Radius);
		Shader.SetGlobalInt("_BokehRenderMode", RenderMode == Rendering.DirectX ? 0 : 1);
		RenderToTexture (_Source, _Destination, _Mesh, _Material, "_Texture");
	}

	void OnDestroy()
	{
		Destroy(_Material);
		Destroy(_Mesh);
		_Destination.Release();
	}
}