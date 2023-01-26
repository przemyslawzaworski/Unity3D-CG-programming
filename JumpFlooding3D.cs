using UnityEngine;
using UnityEngine.Rendering;
using System.Runtime.InteropServices;

public class JumpFlooding3D : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] Shader _PixelShader;
	[SerializeField] int _Resolution = 128;
	[SerializeField] bool _Animation = true;
	[SerializeField] [Range(1, 100000)] int _SeedCount = 2048;
	[SerializeField] [Range(-0.5f, 0.5f)] float _SliceXMin = -0.5f, _SliceXMax = 0.5f;
	[SerializeField] [Range(-0.5f, 0.5f)] float _SliceYMin = -0.5f, _SliceYMax = 0.5f;
	[SerializeField] [Range(-0.5f, 0.5f)] float _SliceZMin = -0.5f, _SliceZMax = 0.5f;
	[SerializeField] [Range( 0.0f, 1.0f)] float _Alpha = 1.0f;
	ComputeBuffer _Seeds, _Voxels;
	Material _Material;
	RenderTexture[] _RenderTextures = new RenderTexture[2];
	int _CVID, _BVID, _JFID;
	bool _Swap = true;

	struct Seed
	{
		public Vector3 Location;
		public Vector3 Color;
	};

	void Start()
	{
		GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
		cube.transform.position = Vector3.zero;
		_Material = new Material(_PixelShader);
		cube.GetComponent<Renderer>().sharedMaterial = _Material;
		RenderTextureDescriptor descriptor = new RenderTextureDescriptor(_Resolution, _Resolution, RenderTextureFormat.ARGBFloat);
		descriptor.dimension = TextureDimension.Tex3D;
		descriptor.volumeDepth = _Resolution;
		for (int i = 0; i < 2; i++)
		{
			_RenderTextures[i] = new RenderTexture(descriptor);
			_RenderTextures[i].enableRandomWrite = true;
			_RenderTextures[i].Create();
			_RenderTextures[i].filterMode = FilterMode.Point;
		}
		_Voxels = new ComputeBuffer(_Resolution * _Resolution * _Resolution, sizeof(float) * 3, ComputeBufferType.Default);	
		Seed[] seeds = new Seed[_SeedCount];
		for (int i = 0; i < seeds.Length; i++)
		{
			int x = Random.Range(0, _Resolution);
			int y = Random.Range(0, _Resolution);
			int z = Random.Range(0, _Resolution);
			float r = Random.Range(0f, 1f);
			float g = Random.Range(0f, 1f);
			float b = Random.Range(0f, 1f);
			seeds[i] = new Seed{Location = new Vector3(x, y, z), Color = new Vector3(r, g, b)};
		}
		_Seeds = new ComputeBuffer(seeds.Length, Marshal.SizeOf(typeof(Seed)), ComputeBufferType.Default);
		_Seeds.SetData(seeds);
		_CVID = _ComputeShader.FindKernel("ClearVoxelsKernel");
		_BVID = _ComputeShader.FindKernel("BuildVoxelsKernel");
		_JFID = _ComputeShader.FindKernel("JumpFloodKernel");
	}

	void Update()
	{
		_Material.SetVector("_SliceMin", new Vector3(_SliceXMin, _SliceYMin, _SliceZMin));
		_Material.SetVector("_SliceMax", new Vector3(_SliceXMax, _SliceYMax, _SliceZMax));
		_Material.SetFloat("_Alpha", _Alpha);
		_ComputeShader.SetInt("_Resolution", _Resolution);
		_ComputeShader.SetInt("_Animation", System.Convert.ToInt32(_Animation));
		_ComputeShader.SetFloat("_MaxSteps", Mathf.Log((float)_Resolution, 2.0f));
		_ComputeShader.SetFloat("_Time", Time.time);
		_ComputeShader.SetBuffer(_CVID, "_Voxels", _Voxels);
		_ComputeShader.Dispatch(_CVID, _Resolution / 8, _Resolution / 8, _Resolution / 8);
		_ComputeShader.SetBuffer(_BVID, "_Seeds", _Seeds);
		_ComputeShader.SetBuffer(_BVID, "_Voxels", _Voxels);
		_ComputeShader.Dispatch(_BVID, (_Seeds.count + 8) / 8, 1, 1);
		int frameCount = 0;
		for (int i = 0; i < _Resolution; i++)
		{
			_ComputeShader.SetInt("_Frame", frameCount);
			int r = System.Convert.ToInt32(!_Swap);
			int w = System.Convert.ToInt32(_Swap);
			_ComputeShader.SetTexture(_JFID, "_Texture3D", _RenderTextures[r]);
			_ComputeShader.SetTexture(_JFID, "_RWTexture3D", _RenderTextures[w]);
			_ComputeShader.SetBuffer(_JFID, "_Voxels", _Voxels);
			_ComputeShader.Dispatch(_JFID, _Resolution / 8, _Resolution / 8, _Resolution / 8);
			_Material.SetTexture("_Volume", _RenderTextures[w]);
			_Swap = !_Swap;
			frameCount++;
		}
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_Seeds.Release();
		_Voxels.Release();
		for (int i = 0; i < 2; i++) _RenderTextures[i].Release();
	}
}