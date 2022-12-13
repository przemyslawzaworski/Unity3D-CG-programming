// Example of using 64-bit unsigned integers in Unity compute shader
// Requirements: Unity 2020.2.0a8 or later and active DX12 graphics API
using UnityEngine;

public class UnsignedInteger64 : MonoBehaviour
{
	[SerializeField] ComputeShader _ComputeShader;

	void Start()
	{
		if (_ComputeShader == null) return;
		ComputeBuffer reader = new ComputeBuffer(4, sizeof(ulong), ComputeBufferType.Default);
		reader.SetData(new ulong[] {172439890993963ul, 657367095657329ul, 277347196953998ul, 844613309877278ul});
		_ComputeShader.SetBuffer(0, "_Reader", reader);
		ComputeBuffer writer = new ComputeBuffer(2, sizeof(ulong), ComputeBufferType.Default);
		_ComputeShader.SetBuffer(0, "_Writer", writer);
		_ComputeShader.Dispatch(0, writer.count, 1, 1); // execute compute shader
		ulong[] result = new ulong[2];
		writer.GetData( result );
		Debug.Log( "172439890993963 + 657367095657329 = " + result[0].ToString()); //   829 806 986 651 292
		Debug.Log( "277347196953998 + 844613309877278 = " + result[1].ToString()); // 1 121 960 506 831 276
		reader.Release();
		writer.Release();
	}
}