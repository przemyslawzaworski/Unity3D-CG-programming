using UnityEngine;
using System.IO;

public class BitonicSorter : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;
	[SerializeField] int _Count = 1048576;
	[SerializeField] bool _Update = false; // test of performance
	ComputeBuffer _Keys, _Values;
	int _Init, _Main;
	const int _ThreadGroupSize = 256; // number of threads in a one thread group 
	const int _MaxParallelGroups = 1024; // the maximum number of all thread groups that can be executed in parallel 
	const int _MaxParallelThreads = (_ThreadGroupSize * _MaxParallelGroups); // maximum number of threads that can be executed in parallel 

	bool IsPowerOfTwo(int number)
	{
		return number > 0 && (number & (number - 1)) == 0;
	}

	float FastRandom(int seed, float min, float max)
	{
		float p = seed * 0.1031f;
		p = p - Mathf.Floor(p);
		p = p + 33.3333f;
		p = p + p;
		return Mathf.Lerp(min, max, p - Mathf.Floor(p));
	}

	void WriteToFile(string filePath, float[] input, uint[] keys, bool sorted)
	{
		StreamWriter writer = new StreamWriter(filePath);
		for (int i = 0; i < input.Length; i++) 
		{
			string text = sorted ? input[keys[i]].ToString("N1") : input[i].ToString("N1");
			writer.WriteLine(text);
		}
		writer.Close();
	}

	void GetWorkGroupSize(int length, out int x, out int y, out int z) 
	{
		x = length <= _MaxParallelThreads ? (length - 1) / _ThreadGroupSize + 1 : _MaxParallelGroups;
		y = length <= _MaxParallelThreads ? 1 : (length - 1) / _MaxParallelThreads + 1;
		z = 1;
	}

	void Sort(ComputeBuffer keys, ComputeBuffer values)
	{
		int count = keys.count;
		int x, y, z;
		GetWorkGroupSize(count, out x, out y, out z);
		_ComputeShader.SetInt("_Count", count);
		for (int dimension = 2; dimension <= count; dimension <<= 1)
		{
			_ComputeShader.SetInt("_Dimension", dimension);
			for (int block = dimension >> 1; block > 0; block >>= 1)
			{
				_ComputeShader.SetInt("_Block", block);
				_ComputeShader.SetBuffer(_Main, "_Keys", keys);
				_ComputeShader.SetBuffer(_Main, "_Values", values);
				_ComputeShader.Dispatch(_Main, x, y, z);
			}
		}
	}

	void Start () 
	{
		if (IsPowerOfTwo(_Count) == false)
		{
			Debug.LogError("Number of elements must be power of two!");
			return;
		}
		_Init = _ComputeShader.FindKernel("BitonicInit");
		_Main = _ComputeShader.FindKernel("BitonicMain");
		_Keys = new ComputeBuffer(_Count, sizeof(uint));
		_Values = new ComputeBuffer(_Count, sizeof(float));
		float[] input = new float[_Count];
		for (int i = 0; i < _Count; i++) input[i] = FastRandom(i, -1000000f, 1000000f);
		_Values.SetData(input);	
		int x, y, z;
		GetWorkGroupSize(_Keys.count, out x, out y, out z);
		_ComputeShader.SetInt("_Count", _Keys.count);
		_ComputeShader.SetBuffer(_Init, "_Keys", _Keys);
		_ComputeShader.Dispatch(_Init, x, y, z);
		Sort(_Keys, _Values);
		uint[] keys = new uint[_Count];
		_Keys.GetData(keys);
		string unsorted = Path.Combine(Path.GetTempPath(), "unsorted.txt");
		WriteToFile(unsorted, input, keys, false);
		System.Diagnostics.Process.Start(unsorted);
		string sorted = Path.Combine(Path.GetTempPath(), "sorted.txt");
		WriteToFile(sorted, input, keys, true);
		System.Diagnostics.Process.Start(sorted);
	}

	void Update()
	{
		if (_Update) Sort(_Keys, _Values);
	}

	void OnDestroy() 
	{
		if (_Keys != null) _Keys.Release();
		if (_Values != null) _Values.Release();
	}
}