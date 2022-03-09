using UnityEngine;

public class SquareRoot : MonoBehaviour
{
	public ComputeShader SquareRootCS;

	void Start()
	{
		ComputeBuffer computeBuffer = new ComputeBuffer (1, sizeof(double));
		SquareRootCS.SetBuffer (0, "_ComputeBuffer", computeBuffer);
		SquareRootCS.Dispatch (0, 1, 1, 1);
		double[] result = new double[1];
		computeBuffer.GetData (result);
		computeBuffer.Release();
		Debug.Log("HLSL: " + result[0].ToString("F20"));
		Debug.Log("C#  : " + System.Math.Sqrt(461.0).ToString("F20"));
	}
}