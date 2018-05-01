// https://github.com/przemyslawzaworski
// Set plane position (Y=0.0)
// Collider is generated from vertex shader, using RWStructuredBuffer to transfer data.

using UnityEngine;

public class rw_structured_buffer : MonoBehaviour 
{
	public Material material;
	public GameObject plane;
	ComputeBuffer compute_buffer;
	Mesh mesh;
	Vector3[] data;

	void Start()
	{
		mesh = plane.GetComponent<Collider>().GetComponent<MeshFilter>().sharedMesh;
		data = mesh.vertices;
		compute_buffer = new ComputeBuffer(data.Length, sizeof(float)*3, ComputeBufferType.Default);
	}

	void Update() 
	{
		Graphics.ClearRandomWriteTargets();
		material.SetPass(0);
		material.SetBuffer("data", compute_buffer);
		Graphics.SetRandomWriteTarget(1, compute_buffer,false);
		compute_buffer.GetData(data);
		if (data!=null && plane.GetComponent<Renderer>().isVisible && Time.frameCount % 2 == 0)
		{
			mesh.vertices = data;
			DestroyImmediate(plane.GetComponent<MeshCollider>());
			MeshCollider mesh_collider = plane.AddComponent<MeshCollider>();
			mesh_collider.sharedMesh = mesh;
		}
	}

	void OnDestroy()
	{
		compute_buffer.Dispose();
	}
}