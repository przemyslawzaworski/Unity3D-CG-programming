using UnityEngine;
using UnityEngine.Rendering;

public class point_cloud_with_shadow : MonoBehaviour
{
	[Header("External variables")]
	public Material material;
	public Camera camera_source;
	public Light light_source;
	[Header("Particle count")]
	public int number = 5000000;
	ComputeBuffer compute_buffer;
	CommandBuffer camera_command_buffer;
	CommandBuffer light_command_buffer;
	
	void Start ()
	{
		camera_command_buffer = new CommandBuffer();
		camera_command_buffer.name = "PointCloudGeometry";
		light_command_buffer = new CommandBuffer();
		light_command_buffer.name = "PointCloudLighting";
		compute_buffer = new ComputeBuffer(number, sizeof(float)*3, ComputeBufferType.Default);
		Vector3[] cloud = new Vector3[number];     
		for (uint i=0; i<number; ++i) 
		{
			cloud[i]=new Vector3();
			cloud[i].x=Random.Range(-10.0f,10.0f);
			cloud[i].y=Random.Range(-10.0f,10.0f);
			cloud[i].z=Random.Range(-10.0f,10.0f);						 		
		}
		compute_buffer.SetData(cloud);	
		material.SetBuffer("cloud", compute_buffer);		
		camera_command_buffer.DrawProcedural(Matrix4x4.identity,material,0,MeshTopology.Points,number);
		camera_source.AddCommandBuffer(CameraEvent.AfterGBuffer, camera_command_buffer);		
		light_command_buffer.DrawProcedural(Matrix4x4.identity,material,0,MeshTopology.Points,number);
		light_source.AddCommandBuffer(LightEvent.BeforeShadowMapPass,light_command_buffer);
	}

	void OnDestroy()
	{
		compute_buffer.Release();
	}
}
