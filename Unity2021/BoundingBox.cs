/*
Efficient calculation of axis aligned bounding box coordinates using Mesh Compute, minimal working example. 
It can be useful to generation of bounding box in real time for highpoly meshes.
Unfortunately, it seems that InterlockedMin / InterlockedMax have a problem with negative floats casted to uint. 
So I use offset to fix this issue, but maybe more elegant solution exists ?
*/

using UnityEngine;
using UnityEngine.Rendering;
using System;
 
public class BoundingBox : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] GameObject _GameObject;

	float _Offset = 10000f;
	float[] _Box = new float[6] {0f,0f,0f,0f,0f,0f}; // minx, miny, minz, maxx, maxy, maxz;
	int _Dimension, _VertexCount;
	ComputeBuffer _ComputeBuffer;
	GraphicsBuffer _GraphicsBuffer;
	Mesh _Mesh;
	MeshRenderer _MeshRenderer;

	void Start()
	{
		_Mesh = _GameObject.GetComponent<MeshFilter>().sharedMesh;
		_Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
		_ComputeBuffer = new ComputeBuffer(6, sizeof(uint), ComputeBufferType.Structured);
		_GraphicsBuffer = _Mesh.GetVertexBuffer(0);
		VertexAttributeDescriptor[] attributes = _Mesh.GetVertexAttributes();
		for (int i = 0; i < attributes.Length; i++) _Dimension += attributes[i].dimension;
		_MeshRenderer = _GameObject.GetComponent<MeshRenderer>();
		_VertexCount = _Mesh.vertexCount;
	}

	void Update()
	{
		_GameObject.transform.Rotate (Vector3.up * 50 * Time.deltaTime, Space.Self);
		uint min = UInt32.MinValue;
		uint max = UInt32.MaxValue;
		uint[] array = new uint[6] {max, max, max, min, min, min};
		_ComputeBuffer.SetData(array);
		_ComputeShader.SetInt("_Dimension", _Dimension);
		_ComputeShader.SetInt("_VertexCount", _VertexCount);
		_ComputeShader.SetFloat("_Offset", _Offset);
		_ComputeShader.SetMatrix("_LocalToWorldMatrix", _MeshRenderer.localToWorldMatrix);
		_ComputeShader.SetBuffer(0, "_ComputeBuffer", _ComputeBuffer);
		_ComputeShader.SetBuffer(0, "_GraphicsBuffer", _GraphicsBuffer);
		_ComputeShader.Dispatch(0, (_VertexCount + 64) / 64, 1, 1);
		_ComputeBuffer.GetData(array);
		for (int i = 0; i < array.Length; i++)
		{
			byte[] bytes = BitConverter.GetBytes(array[i]);
			_Box[i] = BitConverter.ToSingle(bytes, 0) - _Offset;
		}
	}

	void OnDrawGizmos()
	{
		Gizmos.color = Color.yellow;
		Gizmos.DrawSphere(new Vector3(_Box[0], _Box[1], _Box[2]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[3], _Box[1], _Box[2]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[0], _Box[1], _Box[5]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[3], _Box[1], _Box[5]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[0], _Box[4], _Box[2]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[3], _Box[4], _Box[2]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[0], _Box[4], _Box[5]), 0.1f);
		Gizmos.DrawSphere(new Vector3(_Box[3], _Box[4], _Box[5]), 0.1f);
	}

	void OnDestroy()
	{
		_ComputeBuffer.Release();
		_GraphicsBuffer.Release();
	}
}