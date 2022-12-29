using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Some OpenGL ES 3.2 devices don't support structured buffers in Vertex Shader.
// Let's use floating point texture to simulate buffer. 
public class LabyrinthGLES : MonoBehaviour
{
	[SerializeField] Shader _Shader;
	Material _Material;
	Texture2D _Texture;
	int _GridSize, _InstanceCount;
	bool _Support = false;

	uint[] _Uints = new uint[] // encoded 1024 bools into 32 uints
	{
		4294967295,    328961,2149645193,3241828377,1102916972,3745542656, 108007972,  13790345,
		4039458849,2693554196, 141052416, 643878016,2319524024,2335279234, 637555776,   8514880,
		1259082534, 539628548, 582098976,3221447424,1080688690,2147566451,1360009400,1183881473,
		1814370316,1214948480, 367738954,  72189122, 380666156,1425958922,1082408368,4294967295,
	};

	byte[] UintsToBytes(uint[] uints)
	{
		byte[] bytes = new byte[uints.Length * 4];
		System.Buffer.BlockCopy(uints, 0, bytes, 0, bytes.Length);
		return bytes;
	}

	void Awake()
	{
		_Support = SystemInfo.SupportsTextureFormat(TextureFormat.RFloat);
	}

	void Start()
	{
		if (_Support == false) return;
		_Texture = new Texture2D(32, 1, TextureFormat.RFloat, false, false); // 128 bytes in VRAM
		_Texture.name = "Labyrinth";
		_Texture.filterMode = FilterMode.Point;
		_Texture.LoadRawTextureData(UintsToBytes(_Uints));
		_Texture.Apply(false, false);
		_Material = new Material(_Shader);
		_InstanceCount = _Uints.Length * sizeof(uint) * 8;
		_GridSize = Mathf.RoundToInt(Mathf.Sqrt(_InstanceCount));
	}

	void OnRenderObject()
	{
		if (_Support == false) return;
		_Material.SetPass(0);
		_Material.SetTexture("_Texture", _Texture);
		_Material.SetInt("_GridSize", _GridSize);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, 36, _InstanceCount);
	}

	void OnDestroy()
	{
		if (_Material != null) Destroy(_Material);
		if (_Texture != null) Destroy(_Texture);
	}
}