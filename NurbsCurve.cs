using UnityEngine;

public class NurbsCurve : MonoBehaviour
{
	[Header("Rendering")]
	public Shader NurbsCurveShader;
	[Range(2, 1024)] public int VertexCount = 128;
	public Vector4[] ControlPoints = new Vector4[] // x, y, z, weight
	{
		new Vector4(-4f, -4f, 0f, 1f), 
		new Vector4(-2f,  4f, 0f, 1f), 
		new Vector4( 2f, -4f, 0f, 1f),
		new Vector4( 4f,  4f, 0f, 1f)
	};
	[Tooltip("Number of knots = number of control points + degree + 1")]
	public float[] Knots = new float[] {0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f};
	[Header("Debugging")]
	[Range(0f, 1f)] public float CurveParameter = 0.8f;

	private ComputeBuffer _ComputeBuffer;
	private Vector4[] _Element = new Vector4[1] {Vector4.zero};
	private string _Label = "";
	private Material _Material;	

	void Start()
	{
		if (NurbsCurveShader == null) NurbsCurveShader = Shader.Find("Nurbs Curve");
		_Material = new Material(NurbsCurveShader);
		_ComputeBuffer = new ComputeBuffer(1, 16, ComputeBufferType.Default);
		_Material.SetVectorArray("_ControlPoints", new Vector4[16]);
		_Material.SetFloatArray("_Knots", new float[20]);
	}

	void OnRenderObject() 
	{
		Graphics.ClearRandomWriteTargets();
		_Material.SetPass(0);
		_Material.SetBuffer("_ComputeBuffer", _ComputeBuffer);
		_Material.SetVectorArray("_ControlPoints", ControlPoints);
		_Material.SetInt("_ControlPointsLength", ControlPoints.Length);
		_Material.SetFloatArray("_Knots", Knots);
		_Material.SetInt("_KnotsLength", Knots.Length);
		_Material.SetInt("_VertexCount", VertexCount);
		_Material.SetFloat("_CurveParameter", CurveParameter);
		Graphics.SetRandomWriteTarget(1, _ComputeBuffer, false);
		_ComputeBuffer.GetData(_Element);
		_Label = (_Element != null) ? _Element[0].ToString("F3") : string.Empty;
		Graphics.DrawProcedural(MeshTopology.LineStrip, VertexCount, 1);
	}

	void OnGUI()
	{
		GUIStyle style = new GUIStyle();
		style.fontSize = 32;
		GUI.Label(new Rect(50, 50, 400, 100), _Label, style);
	}

	void OnDestroy()
	{
		_ComputeBuffer.Dispose();
	}
}