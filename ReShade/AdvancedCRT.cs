using UnityEngine;
using System.Collections;

public class AdvancedCRT : MonoBehaviour 
{
	public Shader CRTShader;
	public Camera MainCamera;
	
	[Range(0.0f, 1.0f)] public float Amount = 1.0f;
	[Range(1.0f, 8.0f)]  public float Resolution = 1.15f;
	[Range(0.0f, 4.0f)]  public float Gamma = 2.4f;
	[Range(0.0f, 4.0f)]  public float MonitorGamma = 2.2f;
	[Range(0.0f, 3.0f)]  public float Brightness = 0.9f;	
	[Range(2, 4)]  public int ScanlineIntensity = 2;
	public bool ScanlineGaussian = true;
	public bool Curvature = false;
	[Range(0.0f, 2.0f)]  public float CurvatureRadius = 1.5f;
	[Range(0.0f, 0.02f)]  public float CornerSize = 0.01f;
	[Range(0.0f, 4.0f)]  public float ViewerDistance = 2.0f;
	[Range(-0.2f, 0.2f)]  public float AngleX = 0.0f;
	[Range(-0.2f, 0.2f)]  public float AngleY = 0.0f;
	[Range(1.0f, 1.1f)]  public float Overscan = 1.01f;
	public bool Oversample = true;

	Material _Material;
	Vector4 Angle = new Vector4(0.0f, 0.0f, 0.0f, 0.0f);

	void Blit(RenderTexture source, RenderTexture destination, Material mat, int pass, string name)
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
		_Material = new Material(CRTShader);
	}	
	
	void Update ()
	{		
		_Material.SetFloat("Amount", Amount);
		_Material.SetFloat("Resolution", Resolution);
		_Material.SetFloat("Gamma", Gamma);
		_Material.SetFloat("MonitorGamma", MonitorGamma);
		_Material.SetFloat("Brightness", Brightness);
		_Material.SetInt("ScanlineIntensity", ScanlineIntensity);
		_Material.SetInt("ScanlineGaussian", System.Convert.ToInt32(ScanlineGaussian));
		_Material.SetInt("Curvature", System.Convert.ToInt32(Curvature));		
		_Material.SetFloat("CurvatureRadius", CurvatureRadius);
		_Material.SetFloat("CornerSize", CornerSize);
		_Material.SetFloat("ViewerDistance", ViewerDistance);
		Angle.x = AngleX;
		Angle.y = AngleY * (-1.0f);
		_Material.SetVector("Angle", Angle);
		_Material.SetFloat("Overscan", Overscan);
		_Material.SetInt("Oversample", System.Convert.ToInt32(Oversample));		
	}
	
	void OnRenderImage (RenderTexture source, RenderTexture destination) 
	{
		Blit (source, destination, _Material, 0, "BackBuffer");
	}
}