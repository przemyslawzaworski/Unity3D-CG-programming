// Add script to camera and assign shader "DrawCircles". 
// Script renders 2048 circles with single draw call and their center coordinates 
// are calculated once on the CPU and sent to GPU array.
// To use more than 2048 circles, you can use structured buffer, bake point data to texture,
// or just calculate circles center coordinates procedurally (directly inside vertex shader).
using UnityEngine;
 
public class DrawCircles : MonoBehaviour
{
	public Shader shader;
	protected Material material;
 
	void Awake()
	{
		material = new Material(shader);
		float[] bufferX = new float[2048];
		float[] bufferY = new float[2048];
		for (int i=0; i<2048; i++)
		{
			bufferX[i] = Random.Range(0.0f, 120.0f);
			bufferY[i] = Random.Range(0.0f, 120.0f);
		}
		material.SetFloatArray("BufferX", bufferX);
		material.SetFloatArray("BufferY", bufferY);
	}
 
	void OnRenderObject()
	{
		material.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Triangles, 6, 2048);
	}
}