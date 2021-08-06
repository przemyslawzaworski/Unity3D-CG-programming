using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// Version for meshes with 16-bit indices. Add component to scene, assign compute shader.
// Add some objects to the scene (for example built-in Planes). Play.
// Press left mouse click to remove selected triangle from mesh. 
public class DeleteTriangles : MonoBehaviour
{
	public ComputeShader DeleteTrianglesCS;

	private GraphicsBuffer _VertexBuffer, _IndexBuffer;
	private int _Dimension = 0, _Count = 0;
	private Mesh _Mesh;
	private Renderer _Renderer;
	private Ray _Ray;
	private string _CurrentTargetName = "";
	private bool _Enable = false;

	// Add colliders for raycasts. We want to use and remove triangles on mesh instances, so make mesh copies
	void Start()
	{
		MeshFilter[] filters = FindObjectsOfType<MeshFilter>();
		for (int i = 0; i < filters.Length; i++)
		{
			Mesh mesh = filters[i].sharedMesh;
			filters[i].sharedMesh = Instantiate(mesh);
			filters[i].gameObject.AddComponent<MeshCollider>();
		}
	}

	void Load(GameObject target)
	{
		_Dimension = 0;
		_Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
		_Mesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
		VertexAttributeDescriptor[] attributes = _Mesh.GetVertexAttributes();
		for (int i = 0; i < attributes.Length; i++) _Dimension += attributes[i].dimension;
		_Count = _Mesh.triangles.Length / 2 ; // 3 : 1.5  = 2
		_Renderer = target.GetComponentInChildren<Renderer>();
		if (_VertexBuffer != null) _VertexBuffer.Dispose();
		_VertexBuffer = _Mesh.GetVertexBuffer(0);
		if (_IndexBuffer != null) _IndexBuffer.Dispose();
		_IndexBuffer = _Mesh.GetIndexBuffer();
	}

	void Update()
	{
		if (Input.GetMouseButton(0)) 
		{
			_Enable = true;
			_Ray = Camera.main.ScreenPointToRay(Input.mousePosition);
		}
		else
		{
			_Enable = false;
		}
		if (_Mesh == null || _Renderer == null) return;
		if (_Mesh.indexFormat == IndexFormat.UInt16) // I will prepare version for 32-bit (UInt32) indices later
		{
			DeleteTrianglesCS.SetVector("_Origin", _Ray.origin);
			DeleteTrianglesCS.SetVector("_Direction", _Ray.direction);
			DeleteTrianglesCS.SetBuffer(0, "_VertexBuffer", _VertexBuffer);
			DeleteTrianglesCS.SetBuffer(0, "_IndexBuffer", _IndexBuffer);
			DeleteTrianglesCS.SetInt("_Count", _Count);
			DeleteTrianglesCS.SetInt("_Dimension", _Dimension);
			DeleteTrianglesCS.SetMatrix("_LocalToWorldMatrix", _Renderer.localToWorldMatrix);
			DeleteTrianglesCS.Dispatch(0, (_Count + 64) / 64, 1, 1);
		}
	}

	void FixedUpdate()
	{
		if (_Enable)
		{
			RaycastHit hit;
			if (Physics.Raycast(_Ray.origin, _Ray.direction, out hit))
			{
				GameObject target = hit.collider.gameObject;
				if (target.name != _CurrentTargetName)
				{
					_CurrentTargetName = target.name;
					_Mesh = target.GetComponent<MeshFilter>().sharedMesh;
					Load(target);
				}
			}
		}
	}

	void OnDestroy()
	{
		if (_VertexBuffer != null) _VertexBuffer.Dispose();
		if (_IndexBuffer != null) _IndexBuffer.Dispose();
		MeshFilter[] filters = FindObjectsOfType<MeshFilter>();
		for (int i = 0; i < filters.Length; i++)
		{
			Destroy(filters[i].sharedMesh); // remove instances from memory
		}
	}
}