// Just simple example how to create geometry from dynamic texture (Voronoi Diagram). Not optimized.
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using System.Data;

public class VoronoiEdges : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] int _SeedCount = 256;
	[SerializeField] int _Resolution = 1024;
	[SerializeField] bool _Animation = true;
	ComputeBuffer _Seeds, _Vertices, _IndirectBuffer;
	Material _Material;
	RenderTexture _RenderTexture;
	int _TID, _MID;
	Seed[] _SeedArray;

	struct Seed
	{
		public Vector2 Location;
		public Vector3 Color;
	};

	struct Vertex
	{
		public int Cell;
		public float Angle;
		public Vector2 Location;
	};

	struct Edge
	{
		public Vector2 A;
		public Vector2 B;
		public Edge(Vector2 a, Vector2 b) {this.A = a; this.B = b;}
	}

	void Start()
	{
		_Material = new Material(Shader.Find("Hidden/Internal-Colored"));
		_RenderTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
		_RenderTexture.enableRandomWrite = true;
		_RenderTexture.Create();
		_RenderTexture.filterMode = FilterMode.Point;
		_SeedArray = new Seed[_SeedCount];
		for (int i = 0; i < _SeedArray.Length; i++)
		{
			float x = UnityEngine.Random.Range(32f, _Resolution - 32);
			float y = UnityEngine.Random.Range(32f, _Resolution - 32);
			float r = UnityEngine.Random.Range( 0f, 1f);
			float g = UnityEngine.Random.Range( 0f, 1f);
			float b = UnityEngine.Random.Range( 0f, 1f);
			_SeedArray[i] = new Seed{Location = new Vector2(x, y), Color = new Vector3(r, g, b)};
		}
		_Seeds = new ComputeBuffer(_SeedArray.Length, Marshal.SizeOf(typeof(Seed)), ComputeBufferType.Default);
		_Seeds.SetData(_SeedArray);
		_Vertices = new ComputeBuffer(_SeedArray.Length * 16, Marshal.SizeOf(typeof(Vertex)), ComputeBufferType.Append);
		_IndirectBuffer = new ComputeBuffer (4, sizeof(int), ComputeBufferType.IndirectArguments);
		GameObject plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
		plane.transform.localScale = new Vector3(_Resolution / 10f, _Resolution / 10f, _Resolution / 10f);
		plane.transform.position = new Vector3(_Resolution / 2f, 0f, _Resolution / 2f);
		plane.transform.eulerAngles = new Vector3(0, 180f, 0f);
		plane.GetComponent<Renderer>().sharedMaterial = new Material(Shader.Find("Legacy Shaders/Diffuse"));
		plane.GetComponent<Renderer>().sharedMaterial.mainTexture = _RenderTexture;
		_TID = _ComputeShader.FindKernel("TextureGenerationKernel");
		_MID = _ComputeShader.FindKernel("MeshGenerationKernel");
	}

	void OnRenderObject()
	{
		if (_Animation)
		{
			for (int i = 0; i < _SeedArray.Length; i++)
			{
				_SeedArray[i].Location += new Vector2(Mathf.Cos(Time.time + i + 2) * 0.1f, Mathf.Sin(Time.time + i + 2) * 0.1f);
			}
			_Seeds.SetData(_SeedArray);
		}
		_ComputeShader.SetInt("_SeedsCount", _Seeds.count);
		_ComputeShader.SetInt("_Resolution", _Resolution);
		_ComputeShader.SetFloat("_Time", Time.time);
		_ComputeShader.SetBuffer(_TID, "_Seeds", _Seeds);
		_ComputeShader.SetTexture(_TID,"_RWTexture2D", _RenderTexture);
		_ComputeShader.Dispatch(_TID, _Resolution / 8, _Resolution / 8, 1); // execute texture generation kernel
		_Vertices.SetCounterValue(0);
		_ComputeShader.SetBuffer(_MID, "_Seeds", _Seeds);
		_ComputeShader.SetBuffer(_MID, "_Vertices", _Vertices);
		_ComputeShader.SetTexture(_MID,"_Texture2D", _RenderTexture);
		_ComputeShader.Dispatch(_MID, _Resolution / 8, _Resolution / 8, 1); // execute mesh generation kernel
		int[] args = new int[] { 0, 0, 0, 0 };
		ComputeBuffer.CopyCount(_Vertices, _IndirectBuffer, 0);
		_IndirectBuffer.GetData(args);
		int count = args[0];
		List<Edge> edges = new List<Edge>();
		DataTable dataTable = new DataTable();
		dataTable.Columns.Add("Cell", typeof(int));
		dataTable.Columns.Add("Angle", typeof(float));
		dataTable.Columns.Add("Location", typeof(Vector2));
		Vertex[] vertices = new Vertex[count];
		_Vertices.GetData(vertices); // get vertex data from GPU memory
		for (int i = 0; i < vertices.Length; i++)
		{
			dataTable.Rows.Add(vertices[i].Cell, vertices[i].Angle, vertices[i].Location);
		}
		DataView dataView = new DataView(dataTable);
		dataView.Sort = "Cell, Angle";  // sort vertices
		dataTable = dataView.ToTable();
		Vector2 firstElement = (Vector2)dataTable.Rows[0]["Location"];
		for (int i = 0; i < dataTable.Rows.Count; i++)  // create edges from vertices
		{
			Vector2 a = (Vector2)dataTable.Rows[i]["Location"];
			Vector3 b = Vector2.zero;
			if (i < dataTable.Rows.Count - 1)
			{
				if ((int)dataTable.Rows[i]["Cell"] != (int)dataTable.Rows[i + 1]["Cell"])
				{
					b = new Vector2(firstElement.x, firstElement.y);
					firstElement = (Vector2)dataTable.Rows[i + 1]["Location"];
				}
				else
				{
					b = (Vector2)dataTable.Rows[i + 1]["Location"];
				}
				edges.Add(new Edge(a, b));
			}
			else
			{
				b = new Vector2(firstElement.x, firstElement.y);
				edges.Add(new Edge(a, b));
			}
		}
		GL.PushMatrix();
		_Material.SetPass(0);
		_Material.SetColor("_Color", Color.black);
		GL.Begin(GL.LINES);
		for (int i = 0; i < edges.Count; i++) // draw lines
		{
			Edge edge = edges[i];
			GL.Vertex3(edge.A.x, 0, edge.A.y);
			GL.Vertex3(edge.B.x, 0, edge.B.y);
		}
		GL.End();
		GL.PopMatrix();
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_RenderTexture.Release();
		_Seeds.Release();
		_Vertices.Release();
		_IndirectBuffer.Release();
	}
}