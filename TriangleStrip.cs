// Render triangle strip as triangle list
// github.com/przemyslawzaworski
using UnityEngine;
using System.Runtime.InteropServices;

public class TriangleStrip : MonoBehaviour
{
	public Shader TriangleStripShader;

	private ComputeBuffer _ComputeBuffer;
	private Material _Material;
	private int _Count;

	// https://learn.microsoft.com/en-us/windows/win32/direct3d9/triangle-strips
	Vector3[] _Vertices = new Vector3[6]
	{
		new Vector3(-5.0f, -5.0f, 0.0f),
		new Vector3( 0.0f,  5.0f, 0.0f),
		new Vector3( 5.0f, -5.0f, 0.0f),
		new Vector3(10.0f,  5.0f, 0.0f),
		new Vector3(15.0f, -5.0f, 0.0f),
		new Vector3(20.0f,  5.0f, 0.0f),
	};

	void Awake()
	{
		_Count = (_Vertices.Length - 2) * 3;
		_ComputeBuffer = new ComputeBuffer(_Count, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
		_Material = new Material(TriangleStripShader);
		_ComputeBuffer.SetData(_Vertices);
	}

	void OnRenderObject()
	{
		_Material.SetBuffer("_ComputeBuffer", _ComputeBuffer);
		_Material.SetPass(0);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, _Count, 1);
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_ComputeBuffer.Release();
	}
}