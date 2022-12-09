using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Labyrinth : MonoBehaviour
{
	[SerializeField] Shader _Shader;
	ComputeBuffer _StructuredBuffer;
	Material _Material;
	int _GridSize, _InstanceCount;

	uint[] _Uints = new uint[] // encoded 1024 bools into 32 uints
	{
		4294967295,    328961,2149645193,3241828377,1102916972,3745542656, 108007972,  13790345,
		4039458849,2693554196, 141052416, 643878016,2319524024,2335279234, 637555776,   8514880,
		1259082534, 539628548, 582098976,3221447424,1080688690,2147566451,1360009400,1183881473,
		1814370316,1214948480, 367738954,  72189122, 380666156,1425958922,1082408368,4294967295,
	};

	void Awake()
	{
		_StructuredBuffer = new ComputeBuffer(_Uints.Length, sizeof(uint), ComputeBufferType.Default);
		_StructuredBuffer.SetData(_Uints);
		_Material = new Material(_Shader);
		_Material.SetBuffer("_StructuredBuffer", _StructuredBuffer);
		_InstanceCount = _Uints.Length * sizeof(uint) * 8;
		_GridSize = Mathf.RoundToInt(Mathf.Sqrt(_InstanceCount));
	}

	void OnRenderObject()
	{
		_Material.SetPass(0);
		_Material.SetInt("_GridSize", _GridSize);
		Graphics.DrawProceduralNow(MeshTopology.Triangles, 36, _InstanceCount);
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_StructuredBuffer.Release();
	}

	//////////////////////////////////////////////////////////////////////////////////////
	// utils to generate uint array
	//////////////////////////////////////////////////////////////////////////////////////

	byte[] BitArrayToBytes(BitArray bits)
	{
		byte[] bytes = new byte[(bits.Length - 1) / 8 + 1];
		bits.CopyTo(bytes, 0);
		return bytes;
	}

	BitArray BytesToBitArray(byte[] bytes)
	{
		return new BitArray(bytes);
	}	

	uint[] BytesToUints(byte[] bytes)
	{
		uint[] uints = new uint[bytes.Length / 4];
		System.Buffer.BlockCopy(bytes, 0, uints, 0, bytes.Length);
		return uints;
	}

	string[] PrintUints (uint[] uints)
	{
		List<string> lines = new List<string>();
		string line = "";
		for (int i = 0; i < uints.Length; i++) 
		{
			line = line + uints[i].ToString() + ",";
			if ((i+1) % 8 == 0)
			{
				lines.Add(line);
				line = "";
			}
		}
		return lines.ToArray();
	}
}