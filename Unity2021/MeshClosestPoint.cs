using UnityEngine;
using UnityEngine.Rendering;

public class MeshClosestPoint : MonoBehaviour
{
	[SerializeField] private ComputeShader _ComputeShader;
	[SerializeField] private Transform _Point;
	private GraphicsBuffer _VertexBuffer, _IndexBuffer;
	private ComputeBuffer _ComputeBuffer;
	private int _Dimension = 0, _Count = 0;
	private Mesh _Mesh;
	private SubMeshDescriptor _SubMeshDescriptor;
	private Renderer _Renderer;
	private Ray _Ray;
	private string _CurrentTargetName = "";
	private bool _Enable = false;
	private Vector4[] _Vectors;
	private Vector3 _MeshClosestPoint = new Vector3(0f, 0f, 0f);

	void Load(GameObject target)
	{
		if (_Mesh.isReadable == false) return;
		_Dimension = 0;
		_Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
		_Mesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
		_SubMeshDescriptor = _Mesh.GetSubMesh(0);
		VertexAttributeDescriptor[] attributes = _Mesh.GetVertexAttributes();
		for (int i = 0; i < attributes.Length; i++) _Dimension += attributes[i].dimension;
		_Count = _Mesh.triangles.Length / 3;
		_Renderer = target.GetComponentInChildren<Renderer>();
		if (_VertexBuffer != null) _VertexBuffer.Dispose();
		_VertexBuffer = _Mesh.GetVertexBuffer(0);
		if (_IndexBuffer != null) _IndexBuffer.Dispose();
		_IndexBuffer = _Mesh.GetIndexBuffer();
		if (_ComputeBuffer != null) _ComputeBuffer.Dispose();
		_ComputeBuffer = new ComputeBuffer(_Count, 4 * sizeof(float));
		_Vectors = new Vector4[_Count];
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
		_ComputeShader.SetInt("_Count", _Count);
		_ComputeShader.SetInt("_Dimension", _Dimension);
		_ComputeShader.SetInt("_IndexStart", _SubMeshDescriptor.indexStart);
		_ComputeShader.SetInt("_BaseVertex", _SubMeshDescriptor.baseVertex);
		_ComputeShader.SetInt("_IndexFormat", _Mesh.indexFormat == IndexFormat.UInt16 ? 16 : 32);
		_ComputeShader.SetVector("_Point", _Point.position);
		_ComputeShader.SetMatrix("_LocalToWorldMatrix", _Renderer.localToWorldMatrix);
		_ComputeShader.SetBuffer(0, "_VertexBuffer", _VertexBuffer);
		_ComputeShader.SetBuffer(0, "_IndexBuffer", _IndexBuffer);
		_ComputeShader.SetBuffer(0, "_ComputeBuffer", _ComputeBuffer);
		_ComputeShader.Dispatch(0, (_Count + 64) / 64, 1, 1);
		_ComputeBuffer.GetData(_Vectors);
		float minDistance = 1e9f;
		int index = 0;
		for (int i = 0; i < _Vectors.Length; i++)
		{
			float distance = _Vectors[i].w;
			if (distance < minDistance)
			{
				minDistance = distance;
				index = i;
			}
		}
		Vector4 vector = _Vectors[index];
		_MeshClosestPoint.x = vector.x;
		_MeshClosestPoint.y = vector.y;
		_MeshClosestPoint.z = vector.z;
		Debug.DrawLine(_Point.position, _MeshClosestPoint, Color.blue);
	}

	void FixedUpdate()
	{
		if (_Enable)
		{
			if (Physics.Raycast(_Ray.origin, _Ray.direction, out RaycastHit hit))
			{
				GameObject target = hit.collider.gameObject;
				if (target.name != _CurrentTargetName)
				{
					_CurrentTargetName = target.name;
					_Mesh = target.GetComponent<MeshFilter>().sharedMesh;
					if (_Mesh != null) Load(target);
				}
			}
		}
	}

	void OnDestroy()
	{
		if (_VertexBuffer != null) _VertexBuffer.Dispose();
		if (_IndexBuffer != null) _IndexBuffer.Dispose();
		if (_ComputeBuffer != null) _ComputeBuffer.Dispose();
	}
}