// Edit -> Project Settings -> Graphics -> Always Included Shader -> Hidden/FogOfWar

using UnityEngine;

public class FogOfWar : MonoBehaviour 
{
	public Texture2D Map;
	public int Resolution = 1024;
	public float Radius = 0.02f;
	Material material;
	RenderTexture input, output;
	Vector4 center = new Vector4(0.5f,0.5f,0.0f,0.0f);
	bool swap = true;
	
	void Load()
	{
		material = new Material(Shader.Find("Hidden/FogOfWar"));
		input = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.R8);		
		output = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.R8);		
		GetComponent<Renderer>().material = material;
		material.SetTexture("_Map", Map);		
	}
	
	void Blit(RenderTexture source, RenderTexture destination, Material mat)
	{
		RenderTexture.active = destination;
		mat.SetTexture("_MainTex", source);
		GL.PushMatrix();
		GL.LoadOrtho();
		GL.invertCulling = true;
		mat.SetPass(0);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 0.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 0.0f); 
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 1.0f); 
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.invertCulling = false;
		GL.PopMatrix();		
	}
	
	void GenerateFogOfWar ()
	{
		material.SetVector("Center",center);
		material.SetFloat("Radius",Radius);	
		if (swap)
		{
			material.SetTexture("_MainTex", input);
			Blit(input,output,material);
			material.SetTexture("_Buffer", output);
		}
		else
		{
			material.SetTexture("_MainTex", output);
			Blit(output,input,material);
			material.SetTexture("_Buffer", input);
		}
		swap = !swap;
	}
	
	void Movement()
	{
		if (Input.GetKey("a")) center.x -= Time.deltaTime * 0.05f;
		if (Input.GetKey("d")) center.x += Time.deltaTime * 0.05f;
		if (Input.GetKey("s")) center.y -= Time.deltaTime * 0.05f;
		if (Input.GetKey("w")) center.y += Time.deltaTime * 0.05f;
	}
	
	void Start () 
	{
		Load();
	}
	
	void Update () 
	{
		GenerateFogOfWar();
		Movement();	
	}
	
	void OnDestroy ()
	{
		input.Release();
		output.Release();
	}
}