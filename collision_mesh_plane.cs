using UnityEngine;

public class collision_mesh_plane : MonoBehaviour 
{
	public ComputeShader shader;
	public GameObject mesh;
	public GameObject plane;
	public Material material;
	Vector3[] vertices;
	ComputeBuffer input;	
	ComputeBuffer output;
	int handle_init;	
	int handle_main;	
	float[] result;
	string caption;
	
	void Start () 
	{
		handle_init = shader.FindKernel("CSInit");
		handle_main = shader.FindKernel("CSMain");
		vertices = mesh.GetComponent<MeshFilter>().sharedMesh.vertices;
		input = new ComputeBuffer (vertices.Length, 12, ComputeBufferType.Default);
		shader.SetBuffer (handle_main, "input", input);
		input.SetData(vertices);
		output = new ComputeBuffer (1, 4, ComputeBufferType.Default);
		shader.SetBuffer (handle_main, "output", output);
		shader.SetBuffer (handle_init, "output", output);
		result = new float[1];
	}
	
	void Update () 
	{
		if (Input.GetKey(KeyCode.Keypad4) ) mesh.transform.Translate (new Vector3(-0.01f,0.0f,0.0f));		
		if (Input.GetKey(KeyCode.Keypad6) ) mesh.transform.Translate (new Vector3(0.01f,0.0f,0.0f));
		if (Input.GetKey(KeyCode.Keypad7) ) mesh.transform.Translate (new Vector3(0.00f,0.01f,0.0f));		
		if (Input.GetKey(KeyCode.Keypad9) ) mesh.transform.Translate (new Vector3(0.0f,-0.01f,0.0f));	
		if (Input.GetKey(KeyCode.Keypad8) ) mesh.transform.Translate (new Vector3(0.00f,0.00f,0.01f));		
		if (Input.GetKey(KeyCode.Keypad5) ) mesh.transform.Translate (new Vector3(0.0f,0.00f,-0.01f));
		Vector3 A = plane.transform.TransformPoint(new Vector3(10.0f,0.0f,10.0f));
		Vector3 B = plane.transform.TransformPoint(new Vector3(10.0f,0.0f,0.0f));	
		Vector3 C = plane.transform.TransformPoint(new Vector3(0.0f,0.0f,0.0f));
		shader.SetMatrix("ObjectToWorld",mesh.GetComponent<Renderer>().localToWorldMatrix);	
		shader.SetVector("A",A);
		shader.SetVector("B",B);
		shader.SetVector("C",C);
		material.SetVector("A",A);
		material.SetVector("B",B);
		material.SetVector("C",C);
		shader.Dispatch(handle_init, vertices.Length/8, 1, 1);		
		shader.Dispatch (handle_main, vertices.Length/8, 1, 1);
		output.GetData(result);		
		caption=(result[0]>0) ? "Collision detected !" : "";
	}
	
    void OnGUI()
    {
		GUIStyle gui_style = new GUIStyle();
		gui_style.fontSize = 30;
        GUI.Label(new Rect(20, 50, 200,100), caption, gui_style);
    }
	
	void OnDestroy() 
	{
		input.Release();		
		output.Release();
	}
}
