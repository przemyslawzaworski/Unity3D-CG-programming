using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using System;
using System.Collections.Generic;

public class PhongTessellation : MonoBehaviour
{
	public ComputeShader PhongTessellationCS;
	[Range(1,128)] public int TessellationFactor = 16;
	[Range(0f,1f)] public float Phong = 0.5f;

	int _VertexCount = 0;
	ComputeBuffer _ComputeBuffer;
	GraphicsBuffer _GraphicsBuffer;
	Mesh _Mesh;
	string _Name;
	bool _Recalculate = false;
	Attribute[] _Attributes;
	Bounds _Bounds;

	struct Attribute
	{
		public Vector4 Vertex;
		public Vector3 Normal;
		public Vector2 TexCoord;
	}

	byte[] ToByteArray(Attribute[] vectors)
	{
		byte[] bytes = new byte[sizeof(float) * vectors.Length * 9]; 
		for (int i = 0; i < vectors.Length; i++)
		{
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Vertex[0]),   0, bytes, (i*9+0)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Vertex[1]),   0, bytes, (i*9+1)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Vertex[2]),   0, bytes, (i*9+2)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Vertex[3]),   0, bytes, (i*9+3)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Normal[0]),   0, bytes, (i*9+4)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Normal[1]),   0, bytes, (i*9+5)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].Normal[2]),   0, bytes, (i*9+6)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].TexCoord[0]), 0, bytes, (i*9+7)*sizeof(float), sizeof(float));
			Buffer.BlockCopy(BitConverter.GetBytes(vectors[i].TexCoord[1]), 0, bytes, (i*9+8)*sizeof(float), sizeof(float));
		}
		return bytes;
	}

	void Start()
	{
		Mesh mesh = GetComponent<MeshFilter>().sharedMesh;
		if (mesh == null) mesh = Resources.GetBuiltinResource<Mesh>("Sphere.fbx");
		_Name = mesh.name;
		_Bounds = mesh.bounds;
		_Attributes = new Attribute[mesh.triangles.Length];
		Vector3 normal = new Vector3(0.0f, 0.0f, 1.0f);
		Vector2 uv = new Vector2(0.0f, 0.0f);
		for (int i = 0; i < mesh.triangles.Length; i++)
		{
			Vector3 p = mesh.vertices[mesh.triangles[i]];
			if (mesh.normals.Length > 0) normal = mesh.normals[mesh.triangles[i]];
			if (mesh.uv.Length > 0) uv = mesh.uv[mesh.triangles[i]];
			_Attributes[i].Vertex = new Vector4(p.x, p.y, p.z, 1.0f);
			_Attributes[i].Normal = normal;
			_Attributes[i].TexCoord = uv;
		}
		_ComputeBuffer = new ComputeBuffer(9 * _Attributes.Length, sizeof(float), ComputeBufferType.Raw);
		 byte[] bytes = ToByteArray(_Attributes);
		_ComputeBuffer.SetData(bytes);
	}

	void Update()
	{
		_VertexCount = TessellationFactor * TessellationFactor * _Attributes.Length;
		if (_Mesh == null || _Recalculate)
		{
			_Recalculate = false;
			Release();
			_Mesh = new Mesh();
			_Mesh.name = _Name;
			_Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
			_Mesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
			VertexAttributeDescriptor[] attributes = new []
			{
				new VertexAttributeDescriptor(VertexAttribute.Position, VertexAttributeFormat.Float32, 3, stream:0),
				new VertexAttributeDescriptor(VertexAttribute.Normal, VertexAttributeFormat.Float32, 3, stream:0),
				new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2, stream:0),
			}; 
			_Mesh.SetVertexBufferParams(_VertexCount, attributes);
			_Mesh.SetIndexBufferParams(_VertexCount, IndexFormat.UInt32);
			NativeArray<int> indexBuffer = new NativeArray<int>(_VertexCount, Allocator.Temp);
			for (int i = 0; i < _VertexCount; ++i) indexBuffer[i] = i;
			_Mesh.SetIndexBufferData(indexBuffer, 0, 0, indexBuffer.Length, MeshUpdateFlags.DontRecalculateBounds);
			indexBuffer.Dispose();
			SubMeshDescriptor submesh = new SubMeshDescriptor(0, _VertexCount, MeshTopology.Triangles);
			submesh.bounds = _Bounds;
			_Mesh.SetSubMesh(0, submesh);
			_Mesh.bounds = submesh.bounds;
			GetComponent<MeshFilter>().sharedMesh = _Mesh;
			_GraphicsBuffer = _Mesh.GetVertexBuffer(0);
			PhongTessellationCS.SetInt("_VertexCount", _VertexCount);
			PhongTessellationCS.SetInt("_TessellationFactor", TessellationFactor);
			PhongTessellationCS.SetFloat("_Phong", Phong);
			PhongTessellationCS.SetBuffer(0, "_GraphicsBuffer", _GraphicsBuffer);
			PhongTessellationCS.SetBuffer(0, "_ComputeBuffer", _ComputeBuffer);
			PhongTessellationCS.GetKernelThreadGroupSizes(0, out uint x, out uint y, out uint z);
			int threadGroupsX = Mathf.Min((_VertexCount + (int)x - 1) / (int)x, 65535);
			int threadGroupsY = (int)y;
			int threadGroupsZ = (int)z;
			PhongTessellationCS.Dispatch(0, threadGroupsX, threadGroupsY, threadGroupsZ);
		}
	}

	void Release()
	{
		if (_Mesh != null) Destroy(_Mesh);
		if (_GraphicsBuffer != null) _GraphicsBuffer.Release();
	}

	void OnDestroy()
	{
		Release();
		if (_ComputeBuffer != null) _ComputeBuffer.Release();
	}

	void OnValidate()
	{
		_Recalculate = true;
	}
}