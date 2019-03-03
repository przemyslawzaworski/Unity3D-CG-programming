// Add script to quad and assign material with shader. Play.

using UnityEngine;

public class StrangeFluid : MonoBehaviour 
{
	public int Resolution = 512;
	public Material material;
	RenderTexture input, output;
	bool swap = true;
	
	void Blit(RenderTexture source, RenderTexture destination, Material mat, string name)
	{
		RenderTexture.active = destination;
		mat.SetTexture(name, source);
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
			
	void Start () 
	{
		input = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		output = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
		GetComponent<Renderer>().material = material;
	}
	
	void Update () 
	{
		RaycastHit hit;
		if (Input.GetMouseButton(0))
		{
			if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition) , out hit))
				material.SetVector("iMouse", new Vector4(
					hit.textureCoord.x * Resolution, hit.textureCoord.y * Resolution,
					Mathf.Sign(System.Convert.ToSingle(Input.GetMouseButton(0))),
					Mathf.Sign(System.Convert.ToSingle(Input.GetMouseButton(1)))));
		}
		else
		{
			material.SetVector("iMouse", new Vector4(0.0f, 0.0f, -1.0f, -1.0f));
		}
		
		material.SetInt("iFrame",Time.frameCount);
		material.SetVector("iResolution", new Vector4(Resolution,Resolution,0.0f,0.0f));
		
		if (swap)
		{
			material.SetTexture("_BufferA", input);
			Blit(input,output,material,"_BufferA");
			material.SetTexture("_BufferA", output);
		}
		else
		{
			material.SetTexture("_BufferA", output);
			Blit(output,input,material,"_BufferA");
			material.SetTexture("_BufferA", input);
		}
		swap = !swap;
	}
	
	void OnDestroy ()
	{
		input.Release();
		output.Release();
	}
}