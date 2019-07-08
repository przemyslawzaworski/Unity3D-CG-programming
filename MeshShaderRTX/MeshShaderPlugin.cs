using UnityEngine;
using System;
using System.Collections;
using System.Runtime.InteropServices;

public class MeshShaderPlugin : MonoBehaviour
{
	[DllImport("MeshShaderPlugin")]
	static extern IntPtr Execute();

	IEnumerator Start()
	{
		yield return StartCoroutine("CallNativePlugin");
	}

	IEnumerator CallNativePlugin()
	{
		while (true) 
		{
			yield return new WaitForEndOfFrame();
			GL.IssuePluginEvent(Execute(), 1);
		}
	}
}