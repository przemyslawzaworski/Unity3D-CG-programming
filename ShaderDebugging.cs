using UnityEngine;

public class ShaderDebugging : MonoBehaviour 
{
	public GameObject target;
	
	private Material material;	
	private ComputeBuffer buffer;
	private Vector4[] element;
	private string label;
	private Renderer render;
	
	void Load ()
	{
		buffer = new ComputeBuffer(1, 16, ComputeBufferType.Default);
		element = new Vector4[1];
		label = string.Empty;
		render = target.GetComponent<Renderer>(); 
		material = render.material;
	}
	
	void Start () 
	{
		Load();
	}
	
	void Update () 
	{
		Graphics.ClearRandomWriteTargets();
		material.SetPass(0);
		material.SetBuffer("buffer", buffer);
		Graphics.SetRandomWriteTarget(1, buffer, false);
		buffer.GetData(element);
		label = (element!=null && render.isVisible) ? element[0].ToString("F3") : string.Empty;	
	}

	void OnGUI()
	{
		GUIStyle style = new GUIStyle();
		style.fontSize = 32;
		GUI.Label(new Rect(50, 50, 400, 100), label, style);
	}
	
	void OnDestroy()
	{
		buffer.Dispose();
	}
}
