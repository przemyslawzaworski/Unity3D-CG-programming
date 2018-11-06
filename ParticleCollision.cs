using UnityEngine;
 
public class ParticleCollision : MonoBehaviour
{
	public ComputeShader shader;
	public Material material;
	public int resolution = 1024;
	public int amount = 200;
	private ComputeBuffer buffer;
	private int counter = 0;
	
	void Start ()
	{
		buffer = new ComputeBuffer(resolution*resolution, sizeof(float)*4, ComputeBufferType.Default);
		shader.SetBuffer(0, "buffer", buffer);
		material.SetBuffer("buffer", buffer);
		material.SetInt("amount",amount);
		shader.SetInt("amount",amount);		
	}

	void Update ()
	{
		material.SetInt("resolution",resolution);
		shader.SetInt("iFrame",counter);
		shader.SetFloat("iTimeDelta",Time.deltaTime);
		shader.SetInt("resolution",resolution);
		shader.Dispatch(0, resolution / 16, resolution / 16, 1); 
		counter++;		
	}

	void OnDestroy()
	{
		buffer.Release();
	}  
}