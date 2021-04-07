using UnityEngine;

public class DecalPainter : MonoBehaviour
{
	public GameObject TargetObject;
	public Shader DecalPainterShader;
	public Texture2D DecalTexture;
	public bool Debug = true;
	
	private Matrix4x4 _DecalViewMatrix, _DecalProjectionMatrix;
	private Material _TargetMaterial;
	private Material _PaintMaterial;  //unwrapped mesh
	private Mesh _TargetMesh;	
	private Renderer _TargetRenderer;
	private RenderTexture _RenderTexture;	

	void Start()
	{
		_RenderTexture = new RenderTexture(4096, 4096, 0);
		_RenderTexture.Create();
		_PaintMaterial = new Material(DecalPainterShader);
		_TargetRenderer = TargetObject.GetComponent<Renderer>();
		_TargetMesh = TargetObject.GetComponent<MeshFilter>().sharedMesh;
		_TargetMaterial = _TargetRenderer.sharedMaterial;
	}

	void Update()
	{
		_PaintMaterial.SetMatrix("_MeshModelMatrix", _TargetRenderer.localToWorldMatrix);
		RaycastHit hit;
		Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
		if (Physics.Raycast(ray, out hit))
		{
			_DecalViewMatrix = Matrix4x4.TRS(hit.point + hit.normal, Quaternion.LookRotation(-hit.normal, Vector3.up), Vector3.one).inverse;
			_DecalProjectionMatrix = Matrix4x4.Ortho(-0.2f, 0.2f, -0.2f, 0.2f, 0.01f, 1.0f);
			_PaintMaterial.SetMatrix("_DecalViewMatrix", _DecalViewMatrix);
			_PaintMaterial.SetMatrix("_DecalProjectionMatrix", _DecalProjectionMatrix);
			_PaintMaterial.SetTexture("_DecalTexture", DecalTexture);
		}		
		RenderTexture currentRT = RenderTexture.active;
		RenderTexture.active = _RenderTexture;
		GL.Clear(false, true, Color.black, 1.0f);
		_PaintMaterial.SetPass(0);
		Graphics.DrawMeshNow(_TargetMesh, Vector3.zero, Quaternion.identity);
		RenderTexture.active = currentRT;
		_TargetMaterial.mainTexture = _RenderTexture;
	}

	void OnGUI()
	{
		if (Debug)
			GUI.DrawTexture(new Rect(0, 0, 512, 512), _RenderTexture, ScaleMode.ScaleToFit);
	}

	void OnDestroy()
	{
		_RenderTexture.Release();
		Destroy(_PaintMaterial);
	}
}
