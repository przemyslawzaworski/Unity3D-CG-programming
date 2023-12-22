// Select PaintURP.shader to _Shader field;
// then create material with PaintURP-Unlit and assign material to mesh;
using UnityEngine;

public class PaintURP : MonoBehaviour
{
	[SerializeField] private Shader _Shader;
	[SerializeField] private float _Radius = 0.05f;
	[SerializeField] private int _Resolution = 1024;
	[SerializeField] private Color _Color = Color.white;
	[SerializeField] [Range(0.0001f, 1.0f)] private float _Power = 0.1f;

	private Material _Material;
	private Mesh _Mesh;
	private RenderTexture _PaintInput, _PaintOutput, _ColorInput, _ColorOutput;
	private Renderer _Renderer;
	private RenderBuffer[] _RenderBuffers;
	private bool _Swap = true;
	private Vector4 _LastBrushCenter;
	private int _BrushRadiusProperty;
	private int _BrushPowerProperty;
	private int _BrushCenterProperty;
	private int _BrushColorProperty;
	private int _ModelMatrixProperty;
	private int _RayOriginProperty;
	private int _LastBrushCenterProperty;
	private Vector3 _MouseLastPosition;

	void Start()
	{
		_Material = new Material(_Shader);
		_Mesh = this.transform.gameObject.GetComponent<MeshFilter>().sharedMesh;
		RenderTextureFormat format = RenderTextureFormat.ARGBFloat;
		_PaintInput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_PaintOutput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_ColorInput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_ColorOutput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_Renderer =	this.transform.gameObject.GetComponent<MeshRenderer>();
		_Renderer.sharedMaterial.SetTexture("_PaintMap", _PaintOutput);
		_Renderer.sharedMaterial.SetTexture("_ColorMap", _ColorOutput);
		_RenderBuffers = new RenderBuffer[2];
		_BrushRadiusProperty = Shader.PropertyToID("_BrushRadius");
		_BrushPowerProperty = Shader.PropertyToID("_BrushPower");
		_BrushCenterProperty = Shader.PropertyToID("_BrushCenter");
		_BrushColorProperty = Shader.PropertyToID("_BrushColor");
		_ModelMatrixProperty = Shader.PropertyToID("_ModelMatrix");
		_RayOriginProperty = Shader.PropertyToID("_RayOrigin");
		_LastBrushCenterProperty = Shader.PropertyToID("_LastBrushCenter");
		ClearVectors();
	}

	void RenderToTexture (RenderBuffer[] renderBuffers, RenderTexture psrc, 
		RenderTexture pdst, RenderTexture csrc, RenderTexture cdst, Mesh mesh, 
		Material material, string pname, string cname)
	{
		material.SetTexture(pname, psrc);
		material.SetTexture(cname, csrc);
		RenderTexture renderTexture = RenderTexture.active;
		renderBuffers[0] = pdst.colorBuffer;
		renderBuffers[1] = cdst.colorBuffer;
		Graphics.SetRenderTarget(renderBuffers, pdst.depthBuffer);
		material.SetPass(0);
		Graphics.DrawMeshNow(mesh, Vector3.zero, Quaternion.identity);
		RenderTexture.active = renderTexture;
	}

	float ComputeMouseSpeed()
	{
		float speed = ((Input.mousePosition - _MouseLastPosition).magnitude) / Time.deltaTime;
		_MouseLastPosition = Input.mousePosition;
		return speed;
	}

	void ClearVectors()
	{
		_LastBrushCenter = new Vector4(1e6f, 1e6f, 1e6f, 1e6f);
		_Material.SetVector(_LastBrushCenterProperty, _LastBrushCenter);
		_Material.SetVector(_BrushCenterProperty, new Vector4(1e6f, 1e6f, 1e6f, 1e6f));
	}

	void Update()
	{
		if (Input.GetMouseButton(0))
		{
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			if (Physics.Raycast(ray, out RaycastHit hit))
			{
				_Material.SetFloat(_BrushRadiusProperty, _Radius);
				_Material.SetFloat(_BrushPowerProperty, _Power);
				_Material.SetVector(_LastBrushCenterProperty, _LastBrushCenter);
				_Material.SetVector(_BrushCenterProperty, hit.point);
				_Material.SetVector(_BrushColorProperty, _Color);
				_Material.SetVector(_RayOriginProperty, ray.origin);
				_Material.SetMatrix(_ModelMatrixProperty, _Renderer.localToWorldMatrix);
				_LastBrushCenter = hit.point;
			}
			else
			{
				ClearVectors();
			}
		}
		else
		{
			ClearVectors();
		}
		if (_Swap)
		{
			RenderToTexture (_RenderBuffers, _PaintInput, _PaintOutput, _ColorInput, 
				_ColorOutput, _Mesh, _Material, "_RenderTexture", "_ColorTexture");
		}
		else
		{
			RenderToTexture (_RenderBuffers, _PaintOutput, _PaintInput, _ColorOutput, 
				_ColorInput, _Mesh, _Material, "_RenderTexture", "_ColorTexture");
		}
		_Swap = !_Swap;
	}

	void OnGUI()
	{
		GUI.DrawTexture(new Rect(0, 0, 256, 256), _PaintOutput, ScaleMode.ScaleToFit, false, 1.0f);
		GUI.DrawTexture(new Rect(0, 300, 256, 256), _ColorOutput, ScaleMode.ScaleToFit, false, 1.0f);
	}

	void OnDestroy()
	{
		Destroy(_Material);
		_PaintInput.Release();
		_PaintOutput.Release();
		_ColorInput.Release();
		_ColorOutput.Release();
	}
}