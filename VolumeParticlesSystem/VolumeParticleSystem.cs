// Add script to the Main Camera and set "deferred" rendering path
using UnityEngine;
using UnityEngine.Rendering;

public class VolumeParticleSystem : MonoBehaviour
{
	public Shader MainShader;
	public Camera MainCamera;
	public Light MainLight;

	public int ParticleAmount = 16;
	public float ParticleSpeed = 0.5f;
	public float ParticleLifetime = 0.1f;
	[Range(10.0f,100.0f)]
	public float ParticleSpread = 100f;
	[Range(10.0f,100.0f)]
	public float ParticleHeight = 100f;
	[Range(0.0f,1.0f)]
	public float ParticleScale = 0.16f;	
	[Range(0.0f,1.0f)]
	public float ParticleOpacity = 0.0f;	
	public bool DiffuseShading = true;
	public Color StartColor = Color.yellow;
	public Color MiddleColor = Color.red;
	public Color EndColor = Color.black;
	public Transform EmitterPosition;
	public float RotationAxisX = 0.0f;
	public float RotationAxisY = 0.0f;
	public float RotationAxisZ = 0.0f;
	public int EmitterCycles = 1000;
	public KeyCode InitKey = KeyCode.Space;
	public float GroundLevel = 0.0f;
	
	Material material;
	float time = 0.0f;
	
	void Start()
	{
		material = new Material(MainShader);
		CommandBuffer camerabuffer = new CommandBuffer();
		camerabuffer.name = "Particle Buffer (Camera)";
		CommandBuffer lightbuffer = new CommandBuffer();
		lightbuffer.name = "Particle Buffer (Light)";
		camerabuffer.DrawProcedural(Matrix4x4.identity,material,0,MeshTopology.Triangles, 36 * ParticleAmount*ParticleAmount*ParticleAmount);
		MainCamera.AddCommandBuffer(CameraEvent.AfterGBuffer, camerabuffer);
		lightbuffer.DrawProcedural(Matrix4x4.identity,material,0,MeshTopology.Triangles, 36 * ParticleAmount*ParticleAmount*ParticleAmount);
		MainLight.AddCommandBuffer(LightEvent.BeforeShadowMapPass,lightbuffer);
	}
	
	void Update()
	{
		MainCamera.allowHDR = true;
		material.SetInt("_Amount",ParticleAmount);
		material.SetFloat("_Speed",ParticleSpeed);
		material.SetFloat("_Lifetime",ParticleLifetime);
		material.SetFloat("_Spread",ParticleSpread);
		material.SetFloat("_Height",ParticleHeight);
		material.SetFloat("_ParticleScale",ParticleScale);
		material.SetFloat("_ParticleOpacity",ParticleOpacity);
		material.SetFloat("_DiffuseShading",System.Convert.ToSingle(DiffuseShading));
		material.SetVector("_StartColor",StartColor);
		material.SetVector("_MiddleColor",MiddleColor);
		material.SetVector("_EndColor",EndColor);
		material.SetVector("_EmitterPosition",EmitterPosition.position);
		material.SetFloat("_Height",ParticleHeight);		
		material.SetInt("_EmitterCycles",EmitterCycles);
		material.SetFloat("_RotationX",RotationAxisX);
		material.SetFloat("_RotationY",RotationAxisY);
		material.SetFloat("_RotationZ",RotationAxisZ);
		material.SetFloat("_GroundLevel",GroundLevel);		
		time += Time.deltaTime;
		if (Input.GetKeyDown(InitKey)) time = 0.0f;
		material.SetFloat("_Timer",time);
	}
}