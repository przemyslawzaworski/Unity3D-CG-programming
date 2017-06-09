//In Unity3D editor, add 3D Object/Quad to Main Camera. Set quad position at (x=0 ; y=0; z=0.86;). Add current script into quad. Set window size to 512x512 or 1024x1024.
//Put raymarching_direct_compute.compute into Assets/Resources directory. Play.
using UnityEngine;
using System.Collections;

public class raymarching_direct_compute : MonoBehaviour 
{	
	void Start () 
	{
		RenderTexture render_texture = new RenderTexture(1024,1024,0);
		render_texture.enableRandomWrite = true;
		render_texture.Create();
		ComputeShader compute_shader = (ComputeShader)Resources.Load("raymarching_direct_compute");
		compute_shader.SetTexture(0,"render_texture",render_texture);
		compute_shader.Dispatch(0,render_texture.width/8,render_texture.height/8,1);
		Renderer renderer = GetComponent<Renderer>();
        renderer.material = new Material(Shader.Find("Unlit/Texture"));
		renderer.material.mainTexture = render_texture;
	}
}
