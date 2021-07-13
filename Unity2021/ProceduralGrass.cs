// Unity 2021.2 test - Mesh.GetVertexBuffer()
// https://forum.unity.com/threads/feedback-wanted-mesh-compute-shader-access.1096531/#post-7318087
// Tested with RTX 2070, function GenerateQuad() from ProceduralGrass.compute may give incorrect results on Intel integrated graphics
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class ProceduralGrass : MonoBehaviour
{
	public ComputeShader ProceduralGrassCS;
	public Shader ProceduralGrassPS;	
	public Texture2D GrassTexture;
	public int TriangleCount = 2000000;

	GraphicsBuffer _VertexBuffer;
	GraphicsBuffer _NormalBuffer;  	
	GraphicsBuffer _TexcoordBuffer;
	Material _Material;
	Mesh _Mesh;

	void Update()
	{
		if (_Mesh && _Mesh.vertexCount != TriangleCount * 3)
		{
			Release();
		}
		if (_Mesh == null)
		{
			_Mesh = new Mesh();
			_Mesh.name = "ProceduralGrass";
			_Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
			VertexAttributeDescriptor[] attributes = new []
			{
				new VertexAttributeDescriptor(VertexAttribute.Position, stream:0),
				new VertexAttributeDescriptor(VertexAttribute.Normal, stream:1),
				new VertexAttributeDescriptor(VertexAttribute.TexCoord0, stream:2)
			}; 
			_Mesh.SetVertexBufferParams(TriangleCount * 3, attributes);          
			_Mesh.SetIndexBufferParams(TriangleCount * 3, IndexFormat.UInt32);
			NativeArray<int> indexBuffer = new NativeArray<int>(TriangleCount * 3, Allocator.Temp);
			for (int i = 0; i < TriangleCount * 3; ++i) indexBuffer[i] = i;
			_Mesh.SetIndexBufferData(indexBuffer, 0, 0, indexBuffer.Length, MeshUpdateFlags.DontRecalculateBounds | MeshUpdateFlags.DontValidateIndices);
			indexBuffer.Dispose();
			SubMeshDescriptor submesh = new SubMeshDescriptor(0, TriangleCount * 3, MeshTopology.Triangles);
			submesh.bounds = new Bounds(Vector3.zero, new Vector3(2000, 2, 2000));
			_Mesh.SetSubMesh(0, submesh);
			_Mesh.bounds = submesh.bounds;
			GetComponent<MeshFilter>().sharedMesh = _Mesh;
			_Material = new Material(ProceduralGrassPS);
			_Material.mainTexture = GrassTexture;
			GetComponent<MeshRenderer>().sharedMaterial = _Material;
		}
		_VertexBuffer ??= _Mesh.GetVertexBuffer(0);
		_NormalBuffer ??= _Mesh.GetVertexBuffer(1);
		_TexcoordBuffer ??= _Mesh.GetVertexBuffer(2);
		ProceduralGrassCS.SetInt("_TriangleCount", TriangleCount);
		ProceduralGrassCS.SetBuffer(0, "_VertexBuffer", _VertexBuffer);
		ProceduralGrassCS.SetBuffer(0, "_TexcoordBuffer", _TexcoordBuffer);
		ProceduralGrassCS.SetBuffer(0, "_NormalBuffer", _NormalBuffer);
		ProceduralGrassCS.SetFloat("_Time", Time.time);
		ProceduralGrassCS.Dispatch(0, (TriangleCount + 64 - 1) / 64, 1, 1);
	}

	void Release()
	{
		Destroy(_Material);
		Destroy(_Mesh);
		_Mesh = null;
		_VertexBuffer?.Dispose();
		_VertexBuffer = null;
		_TexcoordBuffer?.Dispose();
		_TexcoordBuffer = null;
		_NormalBuffer?.Dispose();
		_NormalBuffer = null;
	}

	void OnDestroy()
	{
		Release();
	}	
}