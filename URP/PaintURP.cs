// Author: Przemyslaw Zaworski
// _Target should have mesh and mesh collider;
// Select PaintURP.shader to _Shader field;
// then create material with PaintURP-Unlit and assign material to mesh;
using UnityEngine;

public class PaintURP : MonoBehaviour
{
	[SerializeField] private GameObject _Target;
	[SerializeField] private Shader _Shader;
	[SerializeField] private float _Radius = 0.05f;
	[SerializeField] private int _Resolution = 2048;
	[SerializeField] private Color _Color = Color.white;
	[SerializeField] [Range(0.0001f, 1.0f)] private float _Power = 0.002f;
	[SerializeField] [Range(0.0001f, 1.0f)] private float _Force = 0.2f;
	[SerializeField] private int _Framerate = 72;
	[SerializeField] private bool _Debug = false;

	private Material _Material;
	private Mesh _Mesh;
	private RenderTexture _PaintInput, _PaintOutput, _ColorInput, _ColorOutput;
	private Renderer _Renderer;
	private RenderBuffer[] _RenderBuffers;
	private bool _Swap = true;
	private Vector4 _LastBrushCenter;
	private Vector4 _LastRayOrigin;
	private Vector3 _MouseLastPosition;
	private Vector4 _ClearVector = new Vector4(1e6f, 1e6f, 1e6f, 1e6f);
	private float _Timer = 0.0f;
	private int _BrushRadiusProperty;
	private int _BrushPowerProperty;
	private int _BrushCenterProperty;
	private int _BrushColorProperty;
	private int _ModelMatrixProperty;
	private int _RayOriginProperty;
	private int _LastBrushCenterProperty;
	private int _BrushMovementProperty;
	private int _BrushForceProperty;
	private int _BrushEndProperty;

	void Start()
	{
		Application.targetFrameRate = _Framerate;
		_Material = new Material(_Shader);
		_Mesh = _Target.transform.gameObject.GetComponent<MeshFilter>().sharedMesh;
		RenderTextureFormat format = RenderTextureFormat.ARGBFloat;
		_PaintInput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_PaintOutput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_ColorInput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_ColorOutput = new RenderTexture(_Resolution, _Resolution, 0, format);
		_Renderer = _Target.transform.gameObject.GetComponent<MeshRenderer>();
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
		_BrushMovementProperty = Shader.PropertyToID("_BrushMovement");
		_BrushForceProperty = Shader.PropertyToID("_BrushForce");
		_BrushEndProperty = Shader.PropertyToID("_BrushEnd");
		ClearVectors();
		ClearRenderTexture(_PaintInput);
		ClearRenderTexture(_PaintOutput);
		ClearRenderTexture(_ColorInput);
		ClearRenderTexture(_ColorOutput);
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

	bool CheckMouseMovement(float threshold)
	{
		bool result = true;
		Vector3 currentMousePosition = Input.mousePosition;
		bool isMoved = currentMousePosition != _MouseLastPosition;
		if (isMoved)
		{
			_Timer = 0.0f;
			result = true;
		}
		else
		{
			_Timer += Time.deltaTime;
			result = (_Timer >= threshold) ? false : true;
		}
		_MouseLastPosition = Input.mousePosition;
		return result;
	}

	void ClearRenderTexture (RenderTexture rt)
	{
		RenderTexture currentActiveRT = RenderTexture.active;
		RenderTexture.active = rt;
		GL.Clear(true, true, Color.clear);
		RenderTexture.active = currentActiveRT;
	}

	void ClearVectors()
	{
		_LastBrushCenter = _ClearVector;
		_Material.SetVector(_LastBrushCenterProperty, _LastBrushCenter);
		_Material.SetVector(_BrushCenterProperty, _ClearVector);
		_Material.SetFloat(_BrushMovementProperty, 1.0f);
	}

	void SetMaterialParameters(Vector3 hitPoint, Vector3 rayOrigin, bool isMoved)
	{
		_Material.SetFloat(_BrushRadiusProperty, _Radius);
		_Material.SetFloat(_BrushPowerProperty, _Power);
		_Material.SetFloat(_BrushForceProperty, _Force);
		_Material.SetVector(_LastBrushCenterProperty, _LastBrushCenter);
		_Material.SetVector(_BrushCenterProperty, hitPoint);
		_Material.SetVector(_RayOriginProperty, rayOrigin);
		_Material.SetMatrix(_ModelMatrixProperty, _Renderer.localToWorldMatrix);
		_Material.SetFloat(_BrushMovementProperty, isMoved ? 1.0f : 0.0f);
	}

	void Update()
	{
		bool isMoved = CheckMouseMovement(0.02f);
		Shader.SetGlobalVector(_BrushColorProperty, _Color);
		bool end = Input.GetMouseButtonUp(0);
		_Material.SetFloat(_BrushEndProperty, end ? 1.0f : 0.0f);
		if (Input.GetMouseButton(0))
		{
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			if (Physics.Raycast(ray, out RaycastHit hit))
			{
				SetMaterialParameters(hit.point, ray.origin, isMoved);
				_LastBrushCenter = hit.point;
				_LastRayOrigin = ray.origin;
			}
			else
			{
				if (!end) ClearVectors();
			}
		}
		else
		{
			if (!end) ClearVectors();
		}
		if (end)
		{
			SetMaterialParameters(_LastBrushCenter, _LastRayOrigin, false);
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
		if (_Debug)
		{
			GUI.DrawTexture(new Rect(0, 0, 256, 256), _PaintOutput, ScaleMode.ScaleToFit, false, 1.0f);
			GUI.DrawTexture(new Rect(0, 300, 256, 256), _ColorOutput, ScaleMode.ScaleToFit, false, 1.0f);
		}
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