/* Basic example of using simple deformation system.
Brush is a object which deforms canvas. Canvas vertices are sent to GPU, then compute shader
calculates distance between vertices in world space and brush center position. Results are sending 
back to CPU, because we need to generate colliders. This is very expensive operation, so we regenerate
collider once per 60 frames.
*/

using UnityEngine;
using System.Runtime.InteropServices;

public class mesh_deformation : MonoBehaviour 
{
	public GameObject brush;
	public GameObject canvas;
	public ComputeShader computeshader;
	
	Mesh mesh;
	Vector3[] local_vertices, world_vertices, brush_center;
	ComputeBuffer local_vertices_buffer,world_vertices_buffer, brush_center_buffer;
	MeshCollider mesh_collider;
	
	void Awake () 
	{ 
		mesh = canvas.GetComponent<Collider>().GetComponent<MeshFilter>().sharedMesh;
		local_vertices = mesh.vertices;
		world_vertices = mesh.vertices;
		for(int i = 0; i < mesh.vertices.Length; i++)
		{
			local_vertices[i]=new Vector3(mesh.vertices[i].x,0.0f,mesh.vertices[i].z);
		}
		mesh.vertices=local_vertices;
		DestroyImmediate(canvas.GetComponent<MeshCollider>());
		mesh_collider = canvas.AddComponent<MeshCollider>();
		mesh_collider.sharedMesh = mesh;
		local_vertices_buffer= new ComputeBuffer (local_vertices.Length, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
		computeshader.SetBuffer (0, "local_vertices_buffer", local_vertices_buffer); 
		local_vertices_buffer.SetData (local_vertices);
		brush_center_buffer= new ComputeBuffer (1, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
		computeshader.SetBuffer (0, "brush_center_buffer", brush_center_buffer);
		brush_center = new Vector3[1];
		brush_center[0]=brush.transform.position;
		brush_center_buffer.SetData (brush_center);
		world_vertices_buffer= new ComputeBuffer (world_vertices.Length, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
		computeshader.SetBuffer (0, "world_vertices_buffer", world_vertices_buffer); 	
	}
	
	void Update () 
	{
		brush_center[0]=brush.transform.position;
		brush_center_buffer.SetData (brush_center);		
		for(int i = 0; i < local_vertices.Length; i++)
		{
			world_vertices[i] = canvas.transform.TransformPoint(local_vertices[i]);											
		}
		world_vertices_buffer.SetData (world_vertices);
		computeshader.Dispatch (0, local_vertices.Length, 1, 1);
		local_vertices_buffer.GetData (local_vertices);
		mesh.vertices=local_vertices;		
		if (Time.frameCount % 60 == 0)
		{
			DestroyImmediate(canvas.GetComponent<MeshCollider>());
			mesh_collider = canvas.AddComponent<MeshCollider>();
			mesh_collider.sharedMesh = mesh;
		}			
	}
	
	void OnDestroy() 
	{
		local_vertices_buffer.Release ();
		world_vertices_buffer.Release ();
		brush_center_buffer.Release();
	}
}
