//Author: Przemyslaw Zaworski
//Assign material with MainShader to Parent GameObject.
//Second shader will be rendered to render texture.
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderReplacement : MonoBehaviour 
{
	public Shader SecondShader;
	public RenderTexture Output;
	public GameObject Parent;
	
	void Start () 
	{
		GameObject Child = new GameObject();
		Child.name = "SubCamera";
		Child.transform.parent = Parent.transform;
		Child.transform.localPosition = new Vector3(0.0f,5.0f,0.0f);
		Child.transform.localEulerAngles=new Vector3(90.0f,0.0f,0.0f);		
		Camera SubCamera = Child.AddComponent<Camera>();
		SubCamera.clearFlags =  CameraClearFlags.SolidColor;
		SubCamera.backgroundColor = Color.black;
		SubCamera.orthographic = true;
		SubCamera.orthographicSize = 5.0f;
		SubCamera.renderingPath = RenderingPath.VertexLit;
		SubCamera.useOcclusionCulling = false;
		SubCamera.allowMSAA = false; 
		SubCamera.allowHDR = false;	
		SubCamera.targetTexture = Output;
		SubCamera.SetReplacementShader (SecondShader, "RenderType");
	}
}
