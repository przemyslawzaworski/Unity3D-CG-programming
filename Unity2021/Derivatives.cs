using UnityEngine;

public class Derivatives : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] Texture2D _Texture;
	RenderTexture _RenderTexture;
	Material _Material;
	bool _Init = false;

	void Start()
	{
		_RenderTexture = new RenderTexture(_Texture.width, _Texture.height, 0,  RenderTextureFormat.Default, RenderTextureReadWrite.Linear);
		_RenderTexture.enableRandomWrite = true;
		_RenderTexture.Create();
		MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
		_Init = meshRenderer != null;
		if (!_Init) return;
		_Material = new Material(Shader.Find("Standard"));
		_Material.SetTexture("_MainTex", _Texture); 
		_Material.SetTexture("_BumpMap", _RenderTexture);
		meshRenderer.material = _Material;
	}

	void Update()
	{
		if (!_Init) return;
		_ComputeShader.SetTexture(0,"_Writer", _RenderTexture);
		_ComputeShader.SetTexture(0, "_Reader", _Texture, 0);
		_ComputeShader.Dispatch(0, _RenderTexture.width / 8, _RenderTexture.height / 8, 1);
	}

	void OnDestroy()
	{
		if (_RenderTexture != null) _RenderTexture.Release();
		if (_Material != null) Destroy(_Material);
	}
}
