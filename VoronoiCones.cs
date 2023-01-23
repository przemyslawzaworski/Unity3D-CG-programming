using UnityEngine;
using System.Collections.Generic;
using System.Runtime.InteropServices;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class VoronoiCones : MonoBehaviour  
{
	[Header("Cone Settings")]
	[SerializeField] Shader _Shader;
	[SerializeField] int _Resolution = 4096;
	[SerializeField] bool _Animation = true;
	[SerializeField] [Range(8,  128)] int _ConeSides = 64;
	[SerializeField] [Range(0f, 10f)] float _ConeRadius = 1f;
	[SerializeField] [Range(0f, 12f)] float _ConeHeight = 10f;
	[Header("Seed Settings")]
	[SerializeField] [Range(1f, 1048576f)] int _SeedCount = 2048;
	[SerializeField] [Range(0f, 1f)] float _SeedSize = 0.2f;
	Material _Material;
	ComputeBuffer _Cone, _Seeds;
	Matrix4x4 _ModelViewProjection;
	RenderTexture _RenderTexture;
	GameObject _Plane;

	struct Seed
	{
		public Vector2 Location;
		public Vector3 Color;
	};

	List<Vector3> GenerateCone(int sides, float radius, float height)
	{
		List<Vector3> vertices = new List<Vector3>();
		List<Vector2> circle = new List<Vector2>();
		float radians = 0.01745329251f;
		float step = 360f / (float) sides * radians;
		for (int i = 0; i <= sides; i++)
		{
			float x = radius * Mathf.Cos(i * step);
			float y = radius * Mathf.Sin(i * step);
			circle.Add(new Vector2(x, y));
		}
		for (int i = 0; i < sides; i++)
		{
			vertices.Add(new Vector3(0f, 0f, -height));
			vertices.Add(new Vector3(circle[i + 1].x, circle[i + 1].y, 0f));
			vertices.Add(new Vector3(circle[i + 0].x, circle[i + 0].y, 0f));
		}
		return vertices;
	}

	void CreateCones()
	{
		if (_Shader == null) _Shader = Shader.Find("Hidden/VoronoiCones");
		_Material = new Material(_Shader);
		_RenderTexture = new RenderTexture(_Resolution, _Resolution, 16, RenderTextureFormat.ARGB32);
		_RenderTexture.Create();
		List<Vector3> vertices = GenerateCone(_ConeSides, _ConeRadius, _ConeHeight);
		_Cone = new ComputeBuffer(vertices.Count, Marshal.SizeOf(typeof(Vector3)), ComputeBufferType.Default);
		_Cone.SetData(vertices);
		_ModelViewProjection.SetRow(0, new Vector4(0.2f,  0.0f,        0.0f, 0.0f)); //orto size = 5, near = -15 and far = 0
		_ModelViewProjection.SetRow(1, new Vector4(0.0f, -0.2f,        0.0f, 0.0f));
		_ModelViewProjection.SetRow(2, new Vector4(0.0f,  0.0f, -0.0666667f, 0.0f));
		_ModelViewProjection.SetRow(3, new Vector4(0.0f,  0.0f,        0.0f, 1.0f));
		_Plane.GetComponent<Renderer>().sharedMaterial.mainTexture = _RenderTexture;
	}

	void CreateSeeds()
	{
		Seed[] seeds = new Seed[_SeedCount];
		for (int i = 0; i < seeds.Length; i++)
		{
			float x = UnityEngine.Random.Range(-5f, 5f);
			float y = UnityEngine.Random.Range(-5f, 5f);
			float r = UnityEngine.Random.Range( 0f, 1f);
			float g = UnityEngine.Random.Range( 0f, 1f);
			float b = UnityEngine.Random.Range( 0f, 1f);
			seeds[i] = new Seed{Location = new Vector2(x, y), Color = new Vector3(r, g, b)};
		}
		_Seeds = new ComputeBuffer(seeds.Length, Marshal.SizeOf(typeof(Seed)), ComputeBufferType.Default);
		_Seeds.SetData(seeds);
	}

	void DeleteCones()
	{
		if (_Cone != null) _Cone.Release();
		if (_Material != null) Destroy(_Material);
		if (_RenderTexture != null) _RenderTexture.Release();
	}

	void DeleteSeeds()
	{
		if (_Seeds != null) _Seeds.Release();
	}

	public void ApplyCones()
	{
		DeleteCones();
		CreateCones();
	}

	public void ApplySeeds()
	{
		DeleteSeeds();
		CreateSeeds();
	}

	void Start()
	{
		_Plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
		CreateCones();
		CreateSeeds();
	}

	void OnRenderObject() 
	{
		RenderTexture current = RenderTexture.active;
		RenderTexture.active = _RenderTexture;
		_Material.SetPass(0);
		_Material.SetBuffer("_Cone", _Cone);
		_Material.SetBuffer("_Seeds", _Seeds);
		_Material.SetMatrix("_ModelViewProjection", _ModelViewProjection);
		_Material.SetInt("_Animation", System.Convert.ToInt32(_Animation));
		_Material.SetFloat("_SeedSize", _SeedSize);
		_Material.SetFloat("_ConeHeight", _ConeHeight);
		GL.Clear(true, true, Color.clear);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, _Cone.count, _Seeds.count);
		RenderTexture.active = current;
	}

	void OnDestroy()
	{
		DeleteCones();
		DeleteSeeds();
	}
}

#if UNITY_EDITOR
[CustomEditor(typeof(VoronoiCones))]
public class VoronoiConesEditor : Editor
{
	public override void OnInspectorGUI()
	{
		DrawDefaultInspector();    
		VoronoiCones vc = (VoronoiCones)target;
		if(GUILayout.Button("Apply Cone Settings")) vc.ApplyCones();
		if(GUILayout.Button("Apply Seed Settings")) vc.ApplySeeds();
	}
}
#endif