//author: Przemyslaw Zaworski

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class map_projection : MonoBehaviour 
{
	public GameObject[] mesh;
	public Terrain terrain;
	public Material material;
	public Color[] colors;
	public int tile = 1;
	public int resolution = 1024;
	
	private RenderTexture A;
	private RenderTexture B;
	
	void RenderToTexture(RenderTexture destination, Material mat)
	{
		RenderTexture.active = destination;
		GL.PushMatrix();
		GL.LoadOrtho();
		GL.invertCulling = true;
		mat.SetPass(0);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 0.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 0.0f); 
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 1.0f); 
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.invertCulling = false;
		GL.PopMatrix();		
	}	
	
	void Start () 
	{
		A = new RenderTexture(resolution,resolution,0);
		A.Create();  
		B = new RenderTexture(resolution,resolution,0);
		B.Create();
		TerrainData terrain_data = terrain.GetComponent<Terrain>().terrainData;
		material.SetFloat("cornerAX",terrain.transform.position.x);
		material.SetFloat("cornerAY",terrain.transform.position.z);
		material.SetFloat("cornerBX",terrain.transform.position.x+terrain_data.size.x*tile);
		material.SetFloat("cornerBY",terrain.transform.position.z+terrain_data.size.z*tile);
		List<Vector3> vertices = new List<Vector3>();
		for (int j=0;j<mesh.Length;j++)
		{
			mesh[j].GetComponent<MeshFilter>().sharedMesh.GetVertices(vertices);
			int[] triangles = mesh[j].GetComponent<MeshFilter>().sharedMesh.triangles;
			material.SetMatrix("_matrix",mesh[j].GetComponent<Renderer>().localToWorldMatrix);
			for (int i=0;i<triangles.Length/6;i++)
			{
				Vector3 a = vertices[triangles[i * 6 + 0]];
				Vector3 b = vertices[triangles[i * 6 + 1]];
				Vector3 c = vertices[triangles[i * 6 + 2]];
				Vector3 d = vertices[triangles[i * 6 + 3]];
				Vector3 e = vertices[triangles[i * 6 + 4]];
				Vector3 f = vertices[triangles[i * 6 + 5]];
				material.SetColor("colorIN", colors[j]);
				material.SetVector("pointA",new Vector4(a.x,a.y,a.z,1.0f));
				material.SetVector("pointB",new Vector4(b.x,b.y,b.z,1.0f));
				material.SetVector("pointC",new Vector4(c.x,c.y,c.z,1.0f));
				material.SetVector("pointD",new Vector4(d.x,d.y,d.z,1.0f));
				material.SetVector("pointE",new Vector4(e.x,e.y,e.z,1.0f));
				material.SetVector("pointF",new Vector4(f.x,f.y,f.z,1.0f));				
				material.SetTexture("Projection", A);
				RenderToTexture(B,material);				
				material.SetTexture("Projection", B);
				RenderToTexture(A,material);
			}
		}
	}
	
	void OnApplicationQuit()
	{
		A.Release();
		B.Release();	
	}
}