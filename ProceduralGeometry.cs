using UnityEngine;
using System.Runtime.InteropServices;
    
public struct Point 
{
	public Vector3 vertex;
	public Vector3 normal;
	public Vector4 tangent;
	public Vector2 uv;
}

public class ProceduralGeometry : MonoBehaviour 
{
	public Material material ;
	public GameObject gameobject;
	private ComputeBuffer computebuffer;
	private int n = 0;

	void Start () 
	{
		Mesh mesh = gameobject.GetComponent<MeshFilter>().sharedMesh;
		n = mesh.triangles.Length;
		Point[] points = new Point[n];
		for (int i = 0; i < n; ++i)
		{
			points[i].vertex = mesh.vertices[mesh.triangles[i]];
			points[i].normal = mesh.normals[mesh.triangles[i]];
			points[i].tangent = mesh.tangents[mesh.triangles[i]];
			points[i].uv = mesh.uv [mesh.triangles [i]];
		}
		computebuffer= new ComputeBuffer (n, Marshal.SizeOf(typeof(Point)), ComputeBufferType.Default);
		computebuffer.SetData (points);
		material.SetBuffer ("points", computebuffer);      
	}

	void OnRenderObject() 
	{
		material.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Triangles, n, 1);
	}

	void OnDestroy() 
	{
		computebuffer.Release ();
	}
	
}
