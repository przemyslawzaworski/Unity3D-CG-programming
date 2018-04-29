using UnityEngine;

public class structured_buffer : MonoBehaviour 
{
	public ComputeShader shader;
	public Material material;
	public int resolution = 1024;
	ComputeBuffer A;
	
	void Start () 
	{
		A = new ComputeBuffer(resolution*resolution, sizeof(float)*4, ComputeBufferType.Default);
		shader.SetBuffer(0, "A", A);
		material.SetBuffer("A",A);
	}
	
	void Update () 
	{
		material.SetInt("resolution",resolution);
		shader.SetFloat("time",Time.time);
		shader.SetInt("resolution",resolution);
		shader.Dispatch(0, resolution / 16, resolution / 16, 1);	
	}
	
	void OnDestroy() 
	{
		A.Release();
	}	
}
