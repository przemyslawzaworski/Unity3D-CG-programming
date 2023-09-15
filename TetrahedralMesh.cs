using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class TetrahedralMesh : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] Shader _VertexPixelShader;
	Bounds _Bounds;
	GameObject _Brush;
	ComputeBuffer _ComputeBuffer;
	Material _Material;
	MaterialPropertyBlock _MaterialPropertyBlock;
	RenderParams _RenderParams;
	int _VertexCount = 0;

	void Start()
	{
		List<Vector4> vertices = new List<Vector4>();
		BinaryReader reader = new BinaryReader(File.Open(Path.Combine(Application.dataPath, "TetrahedralMesh.bin"), FileMode.Open));
		int position = 0;
		int length = (int) reader.BaseStream.Length;
		while (position < length)
		{
			List<Vector3> tetrahedron = new List<Vector3>();
			for (int i = 0; i < 12; i++)
			{
				float x = reader.ReadSingle();
				float y = reader.ReadSingle();
				float z = reader.ReadSingle();
				tetrahedron.Add(new Vector3(x, y, z));
			}
			Vector3 tetrahedronCentroid = MeshCentroid (tetrahedron);
			vertices.AddRange(SortPointsInClockwiseOrder(tetrahedron[0],  tetrahedron[1],  tetrahedron[2], tetrahedronCentroid));
			vertices.AddRange(SortPointsInClockwiseOrder(tetrahedron[3],  tetrahedron[4],  tetrahedron[5], tetrahedronCentroid));
			vertices.AddRange(SortPointsInClockwiseOrder(tetrahedron[6],  tetrahedron[7],  tetrahedron[8], tetrahedronCentroid));
			vertices.AddRange(SortPointsInClockwiseOrder(tetrahedron[9], tetrahedron[10], tetrahedron[11], tetrahedronCentroid));
			position += sizeof(float) * 3 * 12;
		}
		reader.Close();
		_Bounds = new Bounds(vertices[0], Vector3.zero);
		for (int i = 1; i < vertices.Count; i++) _Bounds.Encapsulate(vertices[i]);
		_Brush = GameObject.CreatePrimitive(PrimitiveType.Sphere);
		_ComputeBuffer = new ComputeBuffer(vertices.Count, sizeof(float) * 4);
		_ComputeBuffer.SetData(vertices);
		_Material = new Material(_VertexPixelShader);
		_MaterialPropertyBlock = new MaterialPropertyBlock();
		_RenderParams = new RenderParams(_Material);
		_RenderParams.worldBounds = _Bounds;
		_RenderParams.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
		_RenderParams.receiveShadows = true;
		_RenderParams.matProps = _MaterialPropertyBlock;
		_VertexCount = vertices.Count;
	}

	Vector3 MeshCentroid (List<Vector3> vertices)
	{
		float totalArea = 0.0f;
		Vector3 centroid = new Vector3(0.0f, 0.0f, 0.0f);
		for (int i = 0; i < vertices.Count; i+=3)
		{
			Vector3 a = vertices[i + 0];
			Vector3 b = vertices[i + 1];
			Vector3 c = vertices[i + 2];
			Vector3 center = (a + b + c) / 3f;
			float area = 0.5f * Vector3.Cross(b - a, c - a).magnitude;
			centroid += area * center;
			totalArea += area;
		}
		centroid /= totalArea;
		return centroid;
	}

	List<Vector4> SortPointsInClockwiseOrder(Vector3 a, Vector3 b, Vector3 c, Vector3 tetrahedronCenter)
	{
		Vector3 ba = b - a;
		Vector3 ca = c - a;
		Vector3 triangleNormal = Vector3.Normalize(Vector3.Cross(ba, ca));
		Vector3 triangleCenter = (a + b + c) / 3.0f;
		Vector3 direction = Vector3.Normalize(triangleCenter - tetrahedronCenter);
		bool inside = System.Math.Sign(Vector3.Dot(direction, triangleNormal)) > 0f;
		List<Vector4> vectors = new List<Vector4>();
		Vector4 v1 = inside ? new Vector4(a.x, a.y, a.z, 1f) : new Vector4(c.x, c.y, c.z, 1f);
		Vector4 v2 = new Vector4(b.x, b.y, b.z, 1f);
		Vector4 v3 = inside ? new Vector4(c.x, c.y, c.z, 1f) : new Vector4(a.x, a.y, a.z, 1f);
		vectors.AddRange(new List<Vector4> { v1, v2, v3 });
		return vectors;
	}

	void Update()
	{
		_ComputeShader.SetBuffer(0, "_Vertices", _ComputeBuffer);
		_ComputeShader.SetVector("_Center", _Brush.transform.position);
		_ComputeShader.SetInt("_VertexCount", _VertexCount);
		_ComputeShader.Dispatch(0, ((_VertexCount / 12) + 64) / 64, 1, 1);
		_MaterialPropertyBlock.SetBuffer("_Vertices", _ComputeBuffer);
		Graphics.RenderPrimitives(_RenderParams, MeshTopology.Triangles, _VertexCount, 1);
	}

	void LateUpdate()
	{
		_Brush.transform.position = Camera.main.transform.position + Camera.main.transform.forward * 5f;
	}

	void OnGUI()
	{
		GUI.Label(new Rect(10, 10, 300, 20), "Move sphere to delete tetrahedrons");
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_ComputeBuffer.Release();
	}
}