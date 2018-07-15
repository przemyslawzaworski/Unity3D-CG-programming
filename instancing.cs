using UnityEngine;

public class instancing : MonoBehaviour 
{
	public Mesh Quad;
	public Material GrassMaterial;
	public Texture2D GrassTexture;
	public Vector3 VolumeCenter = new Vector3 (0.0f,0.0f,0.0f);
	public Vector3 VolumeSize = new Vector3 (2000.0f,2000.0f,2000.0f);
	public int R = 100;
	[Range(0.0f,1.0f)]
	public float CutOff = 0.5f;
	
	private ComputeBuffer GeometryBuffer;
	private ComputeBuffer ArgumentsBuffer;
	private Bounds bounds;
	
	void Start () 
	{
		GeometryBuffer = new ComputeBuffer(R*R, 16);	
		Vector4[] geometry = new Vector4[R*R];
		for (int i=0;i<R*R;i++) geometry[i] = new Vector4(i%R,0.0f,(i%(R*R))/R,0.0f);	
		GeometryBuffer.SetData(geometry);
		GrassMaterial.SetBuffer("GeometryBuffer", GeometryBuffer);
		uint[] args = new uint[5];
		ArgumentsBuffer = new ComputeBuffer(1, 20, ComputeBufferType.IndirectArguments);		
		args[0] = (uint)Quad.GetIndexCount(0);
		args[1] = (uint)(R*R);
		args[2] = (uint)Quad.GetIndexStart(0);
		args[3] = (uint)Quad.GetBaseVertex(0);
		args[4] = (uint)0;
		ArgumentsBuffer.SetData(args);
		GrassMaterial.SetTexture ("GrassTexture", GrassTexture);
		bounds = new Bounds(VolumeCenter,VolumeSize);
	}
	
	void Update () 
	{
		GrassMaterial.SetFloat("CutOff",CutOff);
		Graphics.DrawMeshInstancedIndirect(Quad, 0, GrassMaterial, bounds, ArgumentsBuffer,0, null);		
	}
	
	void OnDisable() 
	{
		GeometryBuffer.Release();
		ArgumentsBuffer.Release();
	}
}
