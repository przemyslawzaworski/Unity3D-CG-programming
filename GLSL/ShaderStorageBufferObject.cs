// Minimal working example with Unity 2022 (code is not optimized, I just show language syntax and setup):
using UnityEngine;

public class ShaderStorageBufferObject : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] int _Resolution = 1024;
	[SerializeField] FilterMode _FilterMode = FilterMode.Bilinear;
	ComputeBuffer _RWStructuredBuffer, _ConstantBuffer;
	byte[] _Bytes;
	Texture2D _Texture;

	void Start()
	{
		_RWStructuredBuffer = new ComputeBuffer(_Resolution * _Resolution, sizeof(float), ComputeBufferType.Structured);
		_ConstantBuffer = new ComputeBuffer(2, sizeof(float), ComputeBufferType.Constant);
		_Bytes = new byte[_Resolution * _Resolution * sizeof(float)];
		_Texture = new Texture2D(_Resolution, _Resolution, TextureFormat.RGBA32, false, false);
		GameObject plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
		Material material = plane.GetComponent<Renderer>().material;
		material.shader = Shader.Find("Sprites/Default");
		material.mainTexture = _Texture;
		_Texture.filterMode = _FilterMode;
	}

	void Update()
	{
		_ConstantBuffer.SetData(new float[]{Time.time, (float)_Resolution});
		_ComputeShader.SetConstantBuffer("_UniformBuffer", _ConstantBuffer, 0, 2 * sizeof(float));
		_ComputeShader.SetBuffer(0, "_StorageBuffer", _RWStructuredBuffer);
		_ComputeShader.Dispatch(0, _Resolution / 8, _Resolution / 8, 1);
		_RWStructuredBuffer.GetData(_Bytes);
		_Texture.LoadRawTextureData(_Bytes);
		_Texture.Apply();
	}

	void OnDestroy()
	{
		Destroy(_Texture);
		_RWStructuredBuffer.Release();
		_ConstantBuffer.Release();
	}
}