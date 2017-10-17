using UnityEngine;
using System.Linq;

public class fibonacci : MonoBehaviour 
{
	public ComputeShader computeshader;

	void Start () 
	{
		int[] total = new int[32];
		ComputeBuffer buffer = new ComputeBuffer (32, sizeof(int));
		computeshader.SetBuffer (0, "buffer", buffer);
		computeshader.Dispatch (0, 1, 1, 1);  
		buffer.GetData (total);
		buffer.Release();
		Debug.Log("Sum of the first 32 elements of Fibonacci sequence= "+total.Sum());
	}
}