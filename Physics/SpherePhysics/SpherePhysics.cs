using UnityEngine;

public class SpherePhysics : MonoBehaviour
{
	public struct Sphere
	{
		public Vector3 position;
		public Vector3 velocity;
		public float radius;
		public float massInverse;
	}

	public int instanceCount = 5000;
	public Mesh instanceMesh;
	public Material instanceMaterial;   
	public ComputeShader computeShader;
	public float gravity = 9.8f;
	public Vector3 force = Vector3.zero;
	public Bounds worldBounds = new Bounds(new Vector3(0, 0, 0), new Vector3(10, 10, 10));
	public float drag = 0.1f;	

	private int cachedInstanceCount = -1;
	private int cachedSubMeshIndex = -1;
	private ComputeBuffer SphereBuffer;
	private ComputeBuffer SpherePropsBuffer;
	private ComputeBuffer argsBuffer;
	private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
	private int subMeshIndex = 0;
	private Sphere[] entities;

	void Start()
	{
		argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
		UpdateBuffers();
	}

	void Update()
	{
		if (cachedInstanceCount != instanceCount || cachedSubMeshIndex != subMeshIndex)
			UpdateBuffers();
		computeShader.SetFloat("DeltaTime", Time.deltaTime);
		computeShader.SetVector("ExternalForce", new Vector3(force.x, -gravity + force.z, force.y));
		computeShader.SetVector("WorldBoundsMin", worldBounds.min);
		computeShader.SetVector("WorldBoundsMax", worldBounds.max);
		computeShader.SetFloat("DragCoefficient", drag);
		computeShader.SetInt("Count", instanceCount);
		computeShader.SetBuffer(0, "SphereBuffer", SphereBuffer);
		computeShader.Dispatch(0, instanceCount / 64 + 1, 1, 1);
		instanceMaterial.SetBuffer("SphereBuffer", SphereBuffer);
		instanceMaterial.SetBuffer("SpherePropsBuffer", SpherePropsBuffer);
		Graphics.DrawMeshInstancedIndirect(instanceMesh, subMeshIndex, instanceMaterial, worldBounds, argsBuffer);
	}

	void OnGUI()
	{
		GUI.Label(new Rect(265, 20, 200, 30), "Instance Count: " + instanceCount.ToString());
		instanceCount = (int)GUI.HorizontalSlider(new Rect(25, 20, 200, 30), (float)instanceCount, 1.0f, 50000.0f);
	}

	void UpdateBuffers()
	{
		if (instanceMesh != null)
			subMeshIndex = Mathf.Clamp(subMeshIndex, 0, instanceMesh.subMeshCount - 1);
		if (SphereBuffer != null)
			SphereBuffer.Release();
    
		SphereBuffer = new ComputeBuffer(instanceCount, (3 + 3 + 1 + 1) * sizeof(float));
		entities = new Sphere[instanceCount];
		for (int i = 0; i < instanceCount; i++)
		{
			entities[i].position = Random.insideUnitSphere * 7.0f;
			entities[i].velocity = Random.insideUnitSphere;
			entities[i].radius = Random.Range(0.05f, 0.5f);
			entities[i].massInverse = 1.0f / ((4.0f / 3.0f) * Mathf.PI * Mathf.Pow(entities[i].radius, 3));
		}
		SphereBuffer.SetData(entities);
		instanceMaterial.SetBuffer("SphereBuffer", SphereBuffer);
		if (SpherePropsBuffer != null)
			SpherePropsBuffer.Release();
		SpherePropsBuffer = new ComputeBuffer(instanceCount, 4 * sizeof(float));
		Vector4[] props = new Vector4[instanceCount];
		for (int i = 0; i < instanceCount; i++)
		{
			props[i].x = 0.5f + 0.5f * Random.value;
			props[i].y = 0.5f + 0.5f * Random.value;
			props[i].z = 0.5f + 0.5f * Random.value;
			props[i].w = Random.value;
		}
		SpherePropsBuffer.SetData(props);
		instanceMaterial.SetBuffer("SpherePropsBuffer", SpherePropsBuffer);
		if (instanceMesh != null)
		{
			args[0] = (uint)instanceMesh.GetIndexCount(subMeshIndex);
			args[1] = (uint)instanceCount;
			args[2] = (uint)instanceMesh.GetIndexStart(subMeshIndex);
			args[3] = (uint)instanceMesh.GetBaseVertex(subMeshIndex);
		}
		else
		{
			args[0] = args[1] = args[2] = args[3] = 0;
		}
		argsBuffer.SetData(args);
		cachedInstanceCount = instanceCount;
		cachedSubMeshIndex = subMeshIndex;
	}

	void OnDisable()
	{
		SphereBuffer.Release();
		SpherePropsBuffer.Release();
		argsBuffer.Release();
	}
}