// Add script to quad and assign material with shader. Play.

using UnityEngine;

public class WindFlowMap : MonoBehaviour 
{
	public int Resolution = 2048;
	public Material material;
	RenderTexture RTA1, RTA2, RTB1, RTB2, RTC1, RTC2, RTD1, RTD2;
	bool swap = true;
	
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
			
	void Start () 
	{
		RTA1 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTA2 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTB1 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTB2 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTC1 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTC2 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTD1 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		RTD2 = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT		
		GetComponent<Renderer>().material = material;
	}
	
	void Update () 
	{		
		material.SetInt("iFrame",Time.frameCount);
		material.SetVector("iResolution", new Vector4(Resolution,Resolution,0.0f,0.0f));
		
		if (swap)
		{
			material.SetTexture("_BufferD", RTD1);
			Blit(RTD1, RTD2, material, "_BufferD", 0);
			material.SetTexture("_BufferD", RTD2);	
			
			material.SetTexture("_BufferA", RTA1);
			Blit(RTA1, RTA2, material, "_BufferA", 1);
			material.SetTexture("_BufferA", RTA2);
			
			material.SetTexture("_BufferB", RTB1);
			Blit(RTB1, RTB2, material, "_BufferB", 2);
			material.SetTexture("_BufferB", RTB2);
			
			material.SetTexture("_BufferC", RTC1);
			Blit(RTC1, RTC2, material, "_BufferC", 3);
			material.SetTexture("_BufferC", RTC2);
		
		}
		else
		{
			material.SetTexture("_BufferD", RTD2);
			Blit(RTD2, RTD1, material, "_BufferD", 0);
			material.SetTexture("_BufferD", RTD1);
			
			material.SetTexture("_BufferA", RTA2);
			Blit(RTA2, RTA1, material, "_BufferA", 1);
			material.SetTexture("_BufferA", RTA1);
			
			material.SetTexture("_BufferB", RTB2);
			Blit(RTB2, RTB1, material, "_BufferB", 2);
			material.SetTexture("_BufferB", RTB1);
			
			material.SetTexture("_BufferC", RTC2);
			Blit(RTC2, RTC1, material, "_BufferC", 3);
			material.SetTexture("_BufferC", RTC1);
		
		}
		swap = !swap;
	}
	
	void OnDestroy ()
	{
		RTA1.Release();
		RTA2.Release();
		RTB1.Release();
		RTB2.Release();
		RTC1.Release();
		RTC2.Release();	
		RTD1.Release();
		RTD2.Release();			
	}
}