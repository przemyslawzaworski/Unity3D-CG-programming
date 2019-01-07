using UnityEngine;
using UnityEngine.Rendering;

public class VolumeRenderTexture : MonoBehaviour
{
	public ComputeShader VolumeShader;
	public Material VolumeMaterial;
	RenderTexture VRTA, VRTB;
	float cx, cy, cz;
	bool swap = true;
	
	void Start()
	{
		RenderTextureDescriptor RTD = new RenderTextureDescriptor(256, 256, RenderTextureFormat.ARGB32);
		RTD.dimension = TextureDimension.Tex3D;
		RTD.volumeDepth = 256; 
		VRTA = new RenderTexture(RTD);
		VRTA.enableRandomWrite = true;
		VRTA.Create();
		VRTB = new RenderTexture(RTD);
		VRTB.enableRandomWrite = true;
		VRTB.Create(); 
		cx = cy = cz = 0.5f;
	}

	void Update()
	{
		if (Input.GetKey(KeyCode.W)) cy+=0.001f;
		if (Input.GetKey(KeyCode.S)) cy-=0.001f;
		if (Input.GetKey(KeyCode.A)) cx+=0.001f;
		if (Input.GetKey(KeyCode.D)) cx-=0.001f;
		if (Input.GetKey(KeyCode.Q)) cz+=0.001f;
		if (Input.GetKey(KeyCode.E)) cz-=0.001f;
		VolumeShader.SetFloats("Center",new float[3] {cx, cy, cz});
		if (swap)
		{
			VolumeShader.SetTexture(0, "VolumeReader", VRTA);
			VolumeShader.SetTexture(0, "VolumeWriter", VRTB);
			VolumeShader.Dispatch(0, 256 / 8, 256 / 8, 256 / 8);
		}
		else
		{
			VolumeShader.SetTexture(0, "VolumeReader", VRTB);
			VolumeShader.SetTexture(0, "VolumeWriter", VRTA);
			VolumeShader.Dispatch(0, 256 / 8, 256 / 8, 256 / 8);
		}
		swap = !swap;
		VolumeMaterial.SetTexture("_Volume",VRTB);
	}
}
