using UnityEngine;
using System.Collections;

public class abyss : MonoBehaviour 
{
	public Material material;
	public Camera main_camera;
	GameObject quad;
	GameObject[] cubes;
	
	void environment ()
	{
		cubes = new GameObject[20];
		for (int i=0;i<20;i++)
		{
			cubes[i] = GameObject.CreatePrimitive(PrimitiveType.Cube);
			if (i % 2 == 0.0) cubes[i].transform.position=new Vector3(-3.0f,-2.0f*i+6.0f,5.0f);
			else  cubes[i].transform.position=new Vector3(3.0f,-2.0f*i+6.0f,5.0f);
			Material blocks = new Material(Shader.Find("Unlit/Color"));
			cubes[i].GetComponent<Renderer>().material=blocks;
			cubes[i].GetComponent<Renderer>().material.color=Color.black;
		}
	}
	
	void Start () 
	{
		material.SetFloat("_intensity",1.0f);
		main_camera.transform.position = new Vector3(0.0f,10.0f,0.0f);
		quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
		quad.transform.parent=main_camera.transform;
		quad.transform.position=main_camera.transform.position + new Vector3(0.0f,0.0f,10.0f);
		quad.transform.localScale = new Vector3(100.0f,20.0f,100.0f);
		quad.GetComponent<Renderer>().material=material;
		environment();
	}
	
	void Update () 
	{
		main_camera.transform.position-= new Vector3(0, 2.0f*Time.deltaTime, 0);
		if (main_camera.transform.position.y<0.0f )  material.SetFloat("_intensity",1.0f+Mathf.Abs(transform.position.y)*0.33f);
	}
}
