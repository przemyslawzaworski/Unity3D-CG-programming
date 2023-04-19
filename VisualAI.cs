// Set custom Camera.fieldOfView, Camera.farClipPlane, and use calculated visibility percentages to define whether AI see the player.
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VisualAI : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] GameObject _Player; // _Player should have a separate layer
	[SerializeField] GameObject[] _Enemies;
	[SerializeField] int _Delay = 2; // execute every n-frame for better performance

	Camera[] _Cameras;
	ComputeBuffer _CounterBuffer, _IndirectBuffer;
	RenderTexture _RenderTexture, _TextureArray;
	GUIStyle _GUIStyle = new GUIStyle();
	float[] _Percents;
	uint[] _Data = new uint[] {0};

	void Start()
	{
		_Cameras = new Camera[_Enemies.Length];
		_Percents = new float[_Enemies.Length];
		for (int i = 0; i < _Cameras.Length; i++)
		{
			_Cameras[i] = _Enemies[i].AddComponent<Camera>();
			_Cameras[i].depthTextureMode = DepthTextureMode.Depth;
			_Cameras[i].farClipPlane = 500f;
			_Cameras[i].fieldOfView = 60f;
			_Cameras[i].renderingPath = RenderingPath.DeferredShading;
			_Cameras[i].enabled = false;
		}
		_RenderTexture = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
		_RenderTexture.Create();
		_TextureArray = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
		_TextureArray.dimension = UnityEngine.Rendering.TextureDimension.Tex2DArray;
		_TextureArray.volumeDepth = 2;
		_TextureArray.Create();	
		_CounterBuffer = new ComputeBuffer(1, sizeof(uint), ComputeBufferType.Counter);
		_IndirectBuffer = new ComputeBuffer(1, sizeof(uint), ComputeBufferType.IndirectArguments);
		_IndirectBuffer.SetData(_Data);
		_GUIStyle.fontSize = 32;
		StartCoroutine(UpdateCoroutine());
	}

	void CalculateVisibilityPercentages()
	{
		int index = Time.frameCount % _Enemies.Length;
		_ComputeShader.SetBuffer(0, "_CounterBuffer", _CounterBuffer);
		_CounterBuffer.SetCounterValue(0);
		_Cameras[index].targetTexture = _RenderTexture;
		_Cameras[index].cullingMask = (1 << _Player.layer); // render only player
		_Cameras[index].Render();
		Graphics.CopyTexture(_RenderTexture, 0, 0, _TextureArray, 0, 0);
		_Cameras[index].cullingMask = System.Int32.MaxValue & ~(1 << _Player.layer); // everything except player
		_Cameras[index].Render();
		Graphics.CopyTexture(_RenderTexture, 0, 0, _TextureArray, 1, 0);
		_ComputeShader.SetTexture(0, "_TextureArray", _TextureArray);
		_ComputeShader.Dispatch(0, Mathf.Max(1, _RenderTexture.width / 8), Mathf.Max(1, _RenderTexture.height / 8), 1);
		ComputeBuffer.CopyCount(_CounterBuffer, _IndirectBuffer, 0);
		_IndirectBuffer.GetData(_Data);
		float pixels = (float) (_RenderTexture.width * _RenderTexture.height);
		_Percents[index] = _Data[0] / pixels * 100f;
	}

	IEnumerator UpdateCoroutine()
	{
		while (true)
		{
			yield return new WaitForEndOfFrame();
			if (Time.frameCount % _Delay == 0) CalculateVisibilityPercentages();
		}
	}

	void OnGUI()
	{
		for (int i = 0; i < _Cameras.Length; i++)
		{
			GUI.Label(new Rect(0, i * 50, 200, 50), _Cameras[i].name + " : " + _Percents[i].ToString("N2"), _GUIStyle);
		}
	}

	void OnDestroy()
	{
		if (_CounterBuffer != null) _CounterBuffer.Release();
		if (_IndirectBuffer != null) _IndirectBuffer.Release();
		if (_RenderTexture != null) _RenderTexture.Release();
		if (_TextureArray != null) _TextureArray.Release();
	}
}