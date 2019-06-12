//2D fluid simulation with collision. Obstacles generated procedurally, but also you can, for example,
//fetch depth buffer from camera to define collision with normal geometry.

using UnityEngine;
using System.Collections;

public class FluidSimulation : MonoBehaviour
{
	public Shader FluidShader;
	public int Resolution = 1024;
	Material FluidMaterial;

	RenderTexture RTVA;   //velocity data buffer A
	RenderTexture RTVB;   //velocity data buffer B
	RenderTexture RTDA;   //density data buffer A
	RenderTexture RTDB;   //density data buffer B
	RenderTexture RTPA;   //pressure data buffer A
	RenderTexture RTPB;   //pressure data buffer B
	RenderTexture RTTA;   //temperature data buffer A
	RenderTexture RTTB;   //temperature data buffer B
	RenderTexture RT0;    //composition data buffer	
	RenderTexture RT1;    //divergence data buffer 
	RenderTexture RT2;    //obstacle data buffer
	RenderTexture RT3;    //shading data buffer
	
	float timeStep = 0.125f;
	float impulseTemperature = 10.0f;
	float impulseDensity = 1.0f;
	float temperatureDissipation = 0.99f;
	float velocityDissipation = 0.99f;
	float densityDissipation = 0.9999f;
	float ambientTemperature = 0.0f;
	float smokeBuoyancy = 1.0f;
	float smokeWeight = 0.05f;
	float cellSize = 1.0f;
	float gradientScale = 1.0f;
	Vector2 inverseSize;
	int numJacobiIterations = 50;
	float position = 0.5f;	
	float impluseRadius = 0.08f;
	Vector2 obstaclePos = new Vector2(0.1f, 0.1f);
	int width, height;
	
	void Start()
	{
		width = Resolution;
		height = Resolution;					
		FluidMaterial = new Material(FluidShader);
		inverseSize = new Vector2(1.0f / width, 1.0f / height);	
		RTVA = new RenderTexture(width, height, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
		RTVA.Create();
		RTVB = new RenderTexture(width, height, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
		RTVB.Create();					
		RTDA = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTDA.Create();
		RTDB = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTDB.Create();
		RTTA = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTTA.Create();
		RTTB = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTTB.Create();			
		RTPA = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTPA.filterMode = FilterMode.Point;
		RTPA.Create();
		RTPB = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RTPB.filterMode = FilterMode.Point;
		RTPB.Create();		
		RT0 = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32);
		RT0.Create();								
		RT1 = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RT1.filterMode = FilterMode.Point;
		RT1.Create();
		RT2 = new RenderTexture(width, height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		RT2.filterMode = FilterMode.Point;
		RT2.Create();
		RT3 = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32);
		RT3.Create();		
		GetComponent<Renderer>().material = FluidMaterial;
		FluidMaterial.SetTexture("_Obstacles", RT2);
	}

	void Blit(RenderTexture source, RenderTexture destination, Material mat, string name, int pass)
	{
		RenderTexture.active = destination;
		mat.SetTexture(name, source);
		GL.PushMatrix();
		GL.LoadOrtho();
		GL.invertCulling = true;
		mat.SetPass(pass);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 0.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 0.0f); 
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 0.0f); 
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.invertCulling = false;
		GL.PopMatrix();
	}		

	void Update()
	{
		if (Input.GetKey(KeyCode.Space)) position = position - 0.01f;
		Vector2 impulsePos = new Vector2(Mathf.Sin(position)*0.5f+0.5f, 0.1f);		
		Blit(null, RT2, FluidMaterial, null, 0);		
		FluidMaterial.SetVector("_InverseSize", inverseSize);
		FluidMaterial.SetFloat("_TimeStep", timeStep);
		FluidMaterial.SetFloat("_Dissipation", velocityDissipation);
		FluidMaterial.SetTexture("_Velocity", RTVA);
		FluidMaterial.SetTexture("_Source", RTVA);
		FluidMaterial.SetTexture("_Obstacles", RT2);
		Blit(null, RTVB, FluidMaterial, null, 1);			
		FluidMaterial.SetFloat("_Dissipation", temperatureDissipation);
		FluidMaterial.SetTexture("_Velocity", RTVA);
		FluidMaterial.SetTexture("_Source", RTTA);
		Blit(null, RTTB, FluidMaterial, null, 1);			
		FluidMaterial.SetFloat("_Dissipation", densityDissipation);
		FluidMaterial.SetTexture("_Velocity", RTVA);
		FluidMaterial.SetTexture("_Source", RTDA);
		Blit(null, RTDB, FluidMaterial, null, 1);								
		RenderTexture TMP = RTVA;
		RTVA = RTVB;
		RTVB = TMP;
		TMP = RTTA;
		RTTA = RTTB;
		RTTB = TMP;			
		TMP = RTDA;
		RTDA = RTDB;
		RTDB = TMP;									
		FluidMaterial.SetTexture("_Velocity", RTVA);
		FluidMaterial.SetTexture("_Temperature", RTTA);
		FluidMaterial.SetTexture("_Density", RTDA);
		FluidMaterial.SetFloat("_AmbientTemperature", ambientTemperature);
		FluidMaterial.SetFloat("_Sigma", smokeBuoyancy);
		FluidMaterial.SetFloat("_Kappa", smokeWeight);
		Blit(null, RTVB, FluidMaterial, null, 2);					
		TMP = RTVA;
		RTVA = RTVB;
		RTVB = TMP;		
		FluidMaterial.SetVector("_Point", impulsePos);
		FluidMaterial.SetFloat("_Radius", impluseRadius);
		FluidMaterial.SetFloat("_Fill", impulseTemperature);
		FluidMaterial.SetTexture("_Source", RTTA);
		Blit(null, RTTB, FluidMaterial, null, 3);
		FluidMaterial.SetVector("_Point", impulsePos);
		FluidMaterial.SetFloat("_Radius", impluseRadius);
		FluidMaterial.SetFloat("_Fill", impulseDensity);
		FluidMaterial.SetTexture("_Source", RTDA);
		Blit(null, RTDB, FluidMaterial, null, 3);								
		TMP = RTTA;
		RTTA = RTTB;
		RTTB = TMP;			
		TMP = RTDA;
		RTDA = RTDB;
		RTDB = TMP;						
		FluidMaterial.SetFloat("_HalfInverseCellSize", 0.5f / cellSize);
		FluidMaterial.SetTexture("_Velocity", RTVA);
		Blit(null, RT1, FluidMaterial, null, 4);					
		Graphics.SetRenderTarget(RTPA);
		GL.Clear(false, true, new Color(0, 0, 0, 0));
		Graphics.SetRenderTarget(null);
		for (int i = 0; i < numJacobiIterations; ++i)
		{				
			FluidMaterial.SetTexture("_Pressure", RTPA);
			FluidMaterial.SetTexture("_Divergence", RT1);
			FluidMaterial.SetFloat("_Alpha", -cellSize * cellSize);
			FluidMaterial.SetFloat("_InverseBeta", 0.25f);
			Blit(null, RTPB, FluidMaterial, null, 5);				
			TMP = RTPA;
			RTPA = RTPB;
			RTPB = TMP;
		}		
		FluidMaterial.SetTexture("_Velocity", RTVA);
		FluidMaterial.SetTexture("_Pressure", RTPA);
		FluidMaterial.SetFloat("_GradientScale", gradientScale);
		Blit(null, RTVB, FluidMaterial, null, 6);	
		TMP = RTVA;
		RTVA = RTVB;
		RTVB = TMP;	
		Blit(RTDA, RT0, FluidMaterial, "_Source", 7);		
		Blit(RT0, RT3, FluidMaterial, "_Source", 8);
	}	
}