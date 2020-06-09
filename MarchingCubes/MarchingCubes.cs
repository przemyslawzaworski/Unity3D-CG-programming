using UnityEngine;

public class MarchingCubes : MonoBehaviour
{
	public ComputeShader ScalarFieldCS;
	public ComputeShader MarchingCubesCS;
	public Shader MarchingCubesPS;
	public int MaxVertexCount = 1024*1024*10;
	public int Resolution = 256;
	public bool ShowNormals = true;
	public bool Wireframe = false;

	Material _Material;
	RenderTexture _VolumeTexture;
	ComputeBuffer _TriangleBuffer;
	ComputeBuffer _IndirectBuffer;

	void Start()
	{
		_Material = new Material (MarchingCubesPS);
		RenderTextureDescriptor rtd = new RenderTextureDescriptor(Resolution, Resolution, RenderTextureFormat.RGFloat);
		rtd.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
		rtd.volumeDepth = Resolution; 
		_VolumeTexture = new RenderTexture(rtd);
		_VolumeTexture.enableRandomWrite = true;
		_VolumeTexture.Create();
		_TriangleBuffer = new ComputeBuffer(MaxVertexCount, sizeof(float) * 27, ComputeBufferType.Append);
		_IndirectBuffer = new ComputeBuffer(4, sizeof(int), ComputeBufferType.IndirectArguments);
		MarchingCubesCS.SetInt("_Resolution", Resolution);
		MarchingCubesCS.SetFloat("_IsoLevel", 0.5f);
		MarchingCubesCS.SetBuffer(0, "_TriangleBuffer", _TriangleBuffer);
		ScalarFieldCS.SetInt("_Resolution", Resolution);
	}

	void Update()
	{
		ScalarFieldCS.SetTexture(0, "_VolumeTexture", _VolumeTexture);
		ScalarFieldCS.Dispatch(0, Resolution / 8, Resolution / 8, Resolution / 8);
		_TriangleBuffer.SetCounterValue(0);
		MarchingCubesCS.SetTexture(0, "_VolumeTexture", _VolumeTexture);
		MarchingCubesCS.Dispatch(0, Resolution / 8, Resolution / 8, Resolution / 8);
		int[] args = new int[] { 0, 1, 0, 0 };
		_IndirectBuffer.SetData(args);
		ComputeBuffer.CopyCount(_TriangleBuffer, _IndirectBuffer, 0);
		_IndirectBuffer.GetData(args);
		args[0] *= 3;
		_IndirectBuffer.SetData(args);
	}

	void OnRenderObject()
	{
		_Material.SetPass(0);
		_Material.SetBuffer("_TriangleBuffer", _TriangleBuffer);
		_Material.SetInt("_ShowNormals", System.Convert.ToInt32(ShowNormals));
		_Material.SetInt("_Wireframe", System.Convert.ToInt32(Wireframe));
		Graphics.DrawProceduralIndirect(MeshTopology.Triangles, _IndirectBuffer);
	}

	void OnDestroy()
	{
		_TriangleBuffer.Release();
		_IndirectBuffer.Release();
	}
}
