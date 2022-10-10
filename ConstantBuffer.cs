using UnityEngine;
using System.Runtime.InteropServices;

public class ConstantBuffer : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;

	struct Element
	{
		public int Index;
		public int Radius;
	}

	void Start()
	{
		if (_ComputeShader == null) return;
		ComputeBuffer constantBuffer = new ComputeBuffer(1, Marshal.SizeOf(typeof(Element)), ComputeBufferType.Constant);
		ComputeBuffer structuredBuffer = new ComputeBuffer(1, Marshal.SizeOf(typeof(System.Int32)), ComputeBufferType.Structured);
		_ComputeShader.SetConstantBuffer("_ConstantBuffer", constantBuffer, 0, Marshal.SizeOf(typeof(Element)));
		_ComputeShader.SetBuffer(0, "_StructuredBuffer", structuredBuffer);
		constantBuffer.SetData(new Element[]{new Element() {Index = 1, Radius = 2}});
		_ComputeShader.Dispatch(0, 1, 1, 1 );
		int[] result = new int[1];
		structuredBuffer.GetData( result );
		Debug.Log( "Result is: " + result[0] + ". Should be: " + ( 1 + 2 ));
		constantBuffer.Release();
		structuredBuffer.Release();
	}
}