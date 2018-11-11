using UnityEngine;

public class VolumeRendering : MonoBehaviour 
{
	public Shader shader;
	[Range(0f, 1f)] public float Threshold = 1.0f;
	[Range(1f, 5f)] public float Intensity = 1.0f;
	[Range(0f, 1f)] public float SliceXMin = 0.0f, SliceXMax = 1.0f;
	[Range(0f, 1f)] public float SliceYMin = 0.0f, SliceYMax = 1.0f;
	[Range(0f, 1f)] public float SliceZMin = 0.0f, SliceZMax = 1.0f;
	public string Filename;
	public int Dimension = 128;
	protected Material material;
	protected Quaternion axis = Quaternion.identity;

	void Start () 
	{
		material = new Material(shader);
		GetComponent<MeshFilter>().sharedMesh = GenerateMesh();
		GetComponent<MeshRenderer>().sharedMaterial = material;
		material.SetTexture("_Volume", GenerateVolume(Dimension));
	}
	
	float[] LoadFloatArrayFromFile(string path)
	{
		byte[] a = System.IO.File.ReadAllBytes(path);
		float[] b = new float[a.Length / 4];
		System.Buffer.BlockCopy(a, 0, b, 0, a.Length);
		return b;
	}
	
	Mesh GenerateMesh() 
	{
		var vertices = new Vector3[] 
		{
			new Vector3 (-0.5f, -0.5f, -0.5f),
			new Vector3 ( 0.5f, -0.5f, -0.5f),
			new Vector3 ( 0.5f,  0.5f, -0.5f),
			new Vector3 (-0.5f,  0.5f, -0.5f),
			new Vector3 (-0.5f,  0.5f,  0.5f),
			new Vector3 ( 0.5f,  0.5f,  0.5f),
			new Vector3 ( 0.5f, -0.5f,  0.5f),
			new Vector3 (-0.5f, -0.5f,  0.5f),
		};		
		var triangles = new int[] {0, 2, 1, 0, 3, 2, 2, 3, 4, 2, 4, 5, 1, 2, 5, 1, 5, 6, 0, 7, 4, 0, 4, 3, 5, 4, 7, 5, 7, 6, 0, 6, 7, 0, 1, 6};
		var mesh = new Mesh();
		mesh.vertices = vertices;
		mesh.triangles = triangles;
		mesh.RecalculateNormals();
		return mesh;
	}
	
	Texture3D GenerateVolume (int size)
	{
		float[] source = LoadFloatArrayFromFile(Application.dataPath + "/StreamingAssets/" + Filename);
		Texture3D volume = new Texture3D (size, size, size, TextureFormat.ARGB32, true);
		var voxels = new Color[size*size*size];
		int i = 0;
		Color color = Color.black;
		for (int z = 0; z < size; ++z)
		{
			for (int y = 0; y < size; ++y)
			{
				for (int x = 0; x < size; ++x, ++i)
				{
					color.r = source[i];
					color.g = color.b = color.a = 0.0f;
					voxels[i] = color;
				}
			}
		}
		volume.SetPixels (voxels);
		volume.Apply ();
		volume.filterMode = FilterMode.Point;
		return volume;
	}

	void Update () 
	{
		material.SetFloat("_Threshold", Threshold);
		material.SetFloat("_Intensity", Intensity);
		material.SetVector("_SliceMin", new Vector3(SliceXMin, SliceYMin, SliceZMin));
		material.SetVector("_SliceMax", new Vector3(SliceXMax, SliceYMax, SliceZMax));
		material.SetMatrix("_AxisRotationMatrix", Matrix4x4.Rotate(axis));
	}

	void OnDestroy()
	{
		Destroy(material);
	}

}