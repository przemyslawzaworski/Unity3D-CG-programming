using UnityEngine;
using System;
using System.Collections.Generic;

[RequireComponent (typeof(Camera))]
public class VertexShaderTessellation : MonoBehaviour
{
	public Shader TessellationShader;
	[Range(1, 1024)] public int TessellationFactor = 5;
	public UnityEngine.Rendering.CullMode CullMode = UnityEngine.Rendering.CullMode.Off;

	ComputeBuffer _VertexBuffer;
	Material _Material;
	int _VertexCount = 0;
	Vector4[] _Vertices;

	byte[] ToByteArray(Vector4[] vectors)
	{
		byte[] bytes = new byte[sizeof(float) * vectors.Length * 4]; 
		for (int i = 0; i < vectors.Length * 4; i++)
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i / 4][i % 4]), 0, bytes, i*sizeof(float), sizeof(float));
		return bytes;
	}

	void Start()
	{
		Mesh mesh = Resources.GetBuiltinResource<Mesh>("Quad.fbx");
		List<Vector4> vertices = new List<Vector4>();
		for (int i = 0; i < mesh.triangles.Length; i++)
		{
			Vector3 p = mesh.vertices[mesh.triangles[i]];
			vertices.Add(new Vector4(p.x, p.y, p.z, 1.0f));
		}
		_Vertices = vertices.ToArray();
		Camera.main.clearFlags = CameraClearFlags.SolidColor;
		_Material = new Material(TessellationShader);
		_VertexBuffer = new ComputeBuffer(4 * _Vertices.Length, sizeof(float), ComputeBufferType.Raw);
		 byte[] bytes = ToByteArray(_Vertices);
		_VertexBuffer.SetData(bytes);
	}

	void OnPreRender()
	{
		GL.wireframe = true;
	}

	void OnPostRender()
	{
		_Material.SetBuffer("_VertexBuffer", _VertexBuffer);
		_Material.SetInt("_TessellationFactor", TessellationFactor);
		_Material.SetInt("_CullMode", (int)CullMode);
		_Material.SetPass(0);
		_VertexCount = TessellationFactor * TessellationFactor * _Vertices.Length;
		Graphics.DrawProcedural(MeshTopology.Triangles, _VertexCount, 1);
	}

	void OnGUI()
	{
		GL.wireframe = false;
		GUI.Label(new Rect(10, 10, 200, 30), "Vertex Count: " + _VertexCount.ToString());
	}

	void OnDestroy()
	{
		_VertexBuffer.Release();
		Destroy(_Material);
	}
}