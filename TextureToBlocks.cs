// Converts 3D render texture to cube grid
using UnityEngine;
using UnityEngine.Rendering;

public class TextureToBlocks : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] Shader _VertexShader;
	[SerializeField] Light _DirectionalLight;
	[SerializeField] int _Resolution = 128;
	[SerializeField] float _Scale = 100f;
	Material _Material;
	RenderTexture _RenderTexture;

	void Start()
	{
		_Material = new Material(_VertexShader);
		RenderTextureDescriptor descriptor = new RenderTextureDescriptor(_Resolution, _Resolution, RenderTextureFormat.ARGBFloat);
		descriptor.dimension = TextureDimension.Tex3D;
		descriptor.volumeDepth = _Resolution;
		_RenderTexture = new RenderTexture(descriptor);
		_RenderTexture.enableRandomWrite = true;
		_RenderTexture.Create();
		_RenderTexture.filterMode = FilterMode.Point;
	}

	void OnRenderObject()
	{
		_ComputeShader.SetInt("_Resolution", _Resolution);
		_ComputeShader.SetVector("_WorldSpaceLightPos", _DirectionalLight.transform.rotation * Vector3.forward * (-1f));
		_ComputeShader.SetTexture(0, "_RWTexture3D", _RenderTexture);
		_ComputeShader.Dispatch(0, _Resolution / 8, _Resolution / 8, _Resolution / 8);
		_Material.SetInt("_Resolution", _Resolution);
		_Material.SetFloat("_Scale", _Scale);
		_Material.SetTexture("_Texture3D", _RenderTexture);
		_Material.SetPass(0);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, 36, _Resolution * _Resolution * _Resolution);
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_RenderTexture.Release();
	}
}