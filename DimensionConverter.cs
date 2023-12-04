using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DimensionConverter : MonoBehaviour
{
	public ComputeShader CSShader;
	[Range(1, 6)] 
	[Header(
	"4096x1 = 64x64 = 16x16x16 \n" +
	"1 - Test: Map3DTo1D => Map1DTo3D \n" +
	"2 - Test: Map1DTo3D => Map3DTo1D \n" +
	"3 - Test: Map2DTo1D => Map1DTo2D \n" +
	"4 - Test: Map1DTo2D => Map2DTo1D \n" +
	"5 - Test: Map3DTo2D => Map2DTo3D \n" +
	"6 - Test: Map2DTo3D => Map3DTo2D"
	)] 
	public int Option = 1;

	private int _Kernel1, _Kernel2, _Kernel3, _Kernel4, _Kernel5, _Kernel6;
	private const int _Count = 4096; // might be also 16, 46656 or 262144
	private int _Size2, _Size3;

	void Test1D(int kernel, int result)
	{
		uint[] input = new uint[_Count];
		for (uint n = 0; n < _Count; n++) input[n] = n;
		ComputeBuffer buffer1 = new ComputeBuffer(_Count, 4 * 1);
		buffer1.SetData(input);
		CSShader.SetBuffer(kernel, "_ComputeBuffer1", buffer1);
		ComputeBuffer buffer2 = new ComputeBuffer(_Count, 4 * 2);
		CSShader.SetBuffer(kernel, "_ComputeBuffer2", buffer2);	
		ComputeBuffer buffer3 = new ComputeBuffer(_Count, 4 * 3);
		CSShader.SetBuffer(kernel, "_ComputeBuffer3", buffer3);
		CSShader.Dispatch(kernel, _Count / 8, 1, 1);
		uint[] output = new uint[_Count];
		buffer1.GetData(output);
		Vector2Int[] result2 = new Vector2Int[_Count];
		buffer2.GetData(result2);
		Vector3Int[] result3 = new Vector3Int[_Count];
		buffer3.GetData(result3);
		buffer1.Release();
		buffer2.Release();
		buffer3.Release();
		for (uint i = 0; i < input.Length; i++)
		{
			string chars = (result == 2) ? result2[i].ToString() : result3[i].ToString();
			if (Mathf.Approximately(input[i], output[i]))
			{
				Debug.Log(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
			else
			{
				Debug.LogError(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
		}
	}

	void Test2D(int kernel, int result)
	{
		Vector2Int[] input = new Vector2Int[_Count];
		int n = 0;
		for (int y = 0; y < _Size2; y++)
		{
			for (int x = 0; x < _Size2; x++)
			{
				input[n] = new Vector2Int(x, y);
				n++;
			}
		}
		ComputeBuffer buffer2 = new ComputeBuffer(_Count, 4 * 2);
		buffer2.SetData(input);
		CSShader.SetBuffer(kernel, "_ComputeBuffer2", buffer2);
		ComputeBuffer buffer1 = new ComputeBuffer(_Count, 4 * 1);
		CSShader.SetBuffer(kernel, "_ComputeBuffer1", buffer1);
		ComputeBuffer buffer3 = new ComputeBuffer(_Count, 4 * 3);
		CSShader.SetBuffer(kernel, "_ComputeBuffer3", buffer3);
		CSShader.Dispatch(kernel, _Count / 8, 1, 1);
		Vector2Int[] output = new Vector2Int[_Count];
		buffer2.GetData(output);
		uint[] result1 = new uint[_Count];
		buffer1.GetData(result1);
		Vector3Int[] result3 = new Vector3Int[_Count];
		buffer3.GetData(result3);
		buffer1.Release();
		buffer2.Release();
		buffer3.Release();
		for (uint i = 0; i < input.Length; i++)
		{
			bool a = Mathf.Approximately(input[i].x, output[i].x);
			bool b = Mathf.Approximately(input[i].y, output[i].y);
			string chars = (result == 1) ? result1[i].ToString() : result3[i].ToString();
			if (a && b)
			{
				Debug.Log(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
			else
			{
				Debug.LogError(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
		}
	}

	void Test3D(int kernel, int result)
	{
		Vector3Int[] input = new Vector3Int[_Count];
		int n = 0;
		for (int z = 0; z < _Size3; z++)
		{
			for (int y = 0; y < _Size3; y++)
			{
				for (int x = 0; x < _Size3; x++)
				{
					input[n] = new Vector3Int(x, y, z);
					n++;
				}
			}
		}
		ComputeBuffer buffer3 = new ComputeBuffer(_Count, 4 * 3);
		buffer3.SetData(input);
		CSShader.SetBuffer(kernel, "_ComputeBuffer3", buffer3);
		ComputeBuffer buffer1 = new ComputeBuffer(_Count, 4 * 1);
		CSShader.SetBuffer(kernel, "_ComputeBuffer1", buffer1);
		ComputeBuffer buffer2 = new ComputeBuffer(_Count, 4 * 2);
		CSShader.SetBuffer(kernel, "_ComputeBuffer2", buffer2);
		CSShader.Dispatch(kernel, _Count / 8, 1, 1);
		Vector3Int[] output = new Vector3Int[_Count];
		buffer3.GetData(output);
		uint[] result1 = new uint[_Count];
		buffer1.GetData(result1);
		Vector2Int[] result2 = new Vector2Int[_Count];
		buffer2.GetData(result2);
		buffer1.Release();
		buffer2.Release();
		buffer3.Release();
		for (uint i = 0; i < input.Length; i++)
		{
			bool a = Mathf.Approximately(input[i].x, output[i].x);
			bool b = Mathf.Approximately(input[i].y, output[i].y);
			bool c = Mathf.Approximately(input[i].z, output[i].z);
			string chars = (result == 1) ? result1[i].ToString() : result2[i].ToString();
			if (a && b && c)
			{
				Debug.Log(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
			else
			{
				Debug.LogError(input[i].ToString() + " => " + chars + " ### " + output[i].ToString());
			}
		}
	}

	void Option1()
	{
		Test3D(_Kernel1, 1);
	}

	void Option2()
	{
		Test1D(_Kernel2, 3);
	}

	void Option3()
	{
		Test2D(_Kernel3, 1);
	}

	void Option4()
	{
		Test1D(_Kernel4, 2);
	}

	void Option5()
	{
		Test3D(_Kernel5, 2);
	}

	void Option6()
	{
		Test2D(_Kernel6, 3);
	}

	void Start()
	{
		_Size2 = Mathf.RoundToInt(Mathf.Pow((float)_Count, 1.0f / 2.0f));
		_Size3 = Mathf.RoundToInt(Mathf.Pow((float)_Count, 1.0f / 3.0f));
		CSShader.SetInt("_Size2", _Size2);
		CSShader.SetInt("_Size3", _Size3);
		_Kernel1 = CSShader.FindKernel("CSMain1");
		_Kernel2 = CSShader.FindKernel("CSMain2");
		_Kernel3 = CSShader.FindKernel("CSMain3");
		_Kernel4 = CSShader.FindKernel("CSMain4");
		_Kernel5 = CSShader.FindKernel("CSMain5");
		_Kernel6 = CSShader.FindKernel("CSMain6");
		switch (Option)
		{
			case 1:
				Option1();
				break;
			case 2:
				Option2();
				break;
			case 3:
				Option3();
				break;
			case 4:
				Option4();
				break;
			case 5:
				Option5();
				break;
			case 6:
				Option6();
				break;
		}
	}
}