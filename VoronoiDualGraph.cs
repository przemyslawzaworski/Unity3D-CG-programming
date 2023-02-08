using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class VoronoiDualGraph : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] Shader _VertexPixelShader;
	[SerializeField] int _SeedCount = 2048;
	[SerializeField] int _Resolution = 1024;
	[SerializeField] bool _Animation = true;
	ComputeBuffer _Seeds, _Triangles, _IndirectBuffer, _CounterBuffer;
	Material _Material;
	RenderTexture _RenderTexture;
	int _VK, _DK;
	Seed[] _SeedArray;

	struct Seed
	{
		public Vector2 Location;
		public Vector3 Color;
	};

	struct Triangle
	{
		public Vector2 A;
		public Vector2 B;
		public Vector2 C;
	}

	void Start()
	{
		_Material = new Material(_VertexPixelShader);
		_RenderTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
		_RenderTexture.enableRandomWrite = true;
		_RenderTexture.Create();
		_RenderTexture.filterMode = FilterMode.Point;
		_RenderTexture.wrapMode = TextureWrapMode.Clamp;
		_SeedArray = new Seed[_SeedCount];
		for (int i = 0; i < _SeedArray.Length; i++)
		{
			float x = UnityEngine.Random.Range(16f, _Resolution - 16);
			float y = UnityEngine.Random.Range(16f, _Resolution - 16);
			float r = UnityEngine.Random.Range(0.1f, 0.9f);
			float g = UnityEngine.Random.Range(0.1f, 0.9f);
			float b = UnityEngine.Random.Range(0.1f, 0.9f);
			_SeedArray[i] = new Seed{Location = new Vector2(x, y), Color = new Vector3(r, g, b)};
		}
		_Seeds = new ComputeBuffer(_SeedArray.Length, Marshal.SizeOf(typeof(Seed)), ComputeBufferType.Default);
		_Seeds.SetData(_SeedArray);
		_Triangles = new ComputeBuffer(_SeedArray.Length * 16, Marshal.SizeOf(typeof(Triangle)), ComputeBufferType.Append);
		_IndirectBuffer = new ComputeBuffer (4, sizeof(int), ComputeBufferType.IndirectArguments);
		_IndirectBuffer.SetData(new int[] { 0, 1, 0, 0 });
		_CounterBuffer = new ComputeBuffer(1, 4, ComputeBufferType.Counter);
		GameObject plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
		plane.transform.localScale = new Vector3(_Resolution / 10f, _Resolution / 10f, _Resolution / 10f);
		plane.transform.position = new Vector3(_Resolution / 2f, 0f, _Resolution / 2f);
		plane.transform.eulerAngles = new Vector3(0, 180f, 0f);
		plane.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Legacy Shaders/Diffuse"));
		plane.GetComponent<Renderer>().sharedMaterial.mainTexture = _RenderTexture;	
		_VK = _ComputeShader.FindKernel("VoronoiKernel");
		_DK = _ComputeShader.FindKernel("DelaunayKernel");
	}

	void OnRenderObject()
	{
		if (_Animation)
		{
			for (int i = 0; i < _SeedArray.Length; i++)
			{
				_SeedArray[i].Location += new Vector2(Mathf.Cos(Time.time + i + 2), Mathf.Sin(Time.time + i + 2)) * 0.08f;
			}
			_Seeds.SetData(_SeedArray);
		}
		_ComputeShader.SetInt("_SeedsCount", _Seeds.count);
		_ComputeShader.SetInt("_Resolution", _Resolution);
		_ComputeShader.SetTexture(_VK,"_RWTexture2D", _RenderTexture);
		_ComputeShader.SetBuffer(_VK, "_Seeds", _Seeds);
		_ComputeShader.Dispatch(_VK, _Resolution / 8, _Resolution / 8, 1);
		_Triangles.SetCounterValue(0);
		_CounterBuffer.SetCounterValue(0);
		_ComputeShader.SetTexture(_DK,"_Texture2D", _RenderTexture);
		_ComputeShader.SetBuffer(_DK, "_Seeds", _Seeds);
		_ComputeShader.SetBuffer(_DK, "_Triangles", _Triangles);
		_ComputeShader.SetBuffer(_DK, "_CounterBuffer", _CounterBuffer);
		_ComputeShader.Dispatch(_DK, _Resolution / 8, _Resolution / 8, 1);
		int[] args = new int[] { 0, 1, 0, 0 };
		_IndirectBuffer.SetData(args);
		ComputeBuffer.CopyCount(_CounterBuffer, _IndirectBuffer, 0);
		_Material.SetPass(0);
		_Material.SetBuffer("_TriangleBuffer", _Triangles);
		Graphics.DrawProceduralIndirectNow(MeshTopology.Triangles, _IndirectBuffer);
	}

	void OnDestroy()
	{
		if (_Material != null) Destroy(_Material);
		if (_RenderTexture != null) _RenderTexture.Release();
		if (_Seeds != null) _Seeds.Release();
		if (_Triangles != null) _Triangles.Release();
		if (_IndirectBuffer != null) _IndirectBuffer.Release();
		if (_CounterBuffer != null) _CounterBuffer.Release();
	}
}