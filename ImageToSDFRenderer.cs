using UnityEngine;

public class ImageToSDFRenderer: MonoBehaviour
{
	[SerializeField] private Shader _Shader;
	[SerializeField] private Texture2D _PaintMask;
	private Camera _Camera;
	private Material _Material;
	private Vector3 _LastHitPoint = Vector3.zero;
	private int _PaintMaskProperty;
	private int _FrustumProperty;
	private int _CameraInverseProperty;
	private int _LastHitPointProperty;
	private int _HitPointProperty;
	private int _RayOriginProperty;

	void Start()
	{
		_Camera = Camera.main;
		_Material = new Material(_Shader);
		_PaintMaskProperty = Shader.PropertyToID("_PaintMask");
		_FrustumProperty = Shader.PropertyToID("_FrustumCorners");
		_CameraInverseProperty = Shader.PropertyToID("_CameraInverseMatrix");
		_LastHitPointProperty = Shader.PropertyToID("_PainterLastHitPoint");
		_HitPointProperty = Shader.PropertyToID("_PainterHitPoint");
		_RayOriginProperty = Shader.PropertyToID("_PainterRayOrigin");
	}

	Matrix4x4 GetFrustumCorners(Camera camera)
	{
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		float fov = Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
		Vector3 toRight = Vector3.right * fov * camera.aspect;
		Vector3 toTop = Vector3.up * fov;
		frustumCorners.SetRow(0, -Vector3.forward - toRight + toTop);
		frustumCorners.SetRow(1, -Vector3.forward + toRight + toTop);
		frustumCorners.SetRow(2, -Vector3.forward + toRight - toTop);
		frustumCorners.SetRow(3, -Vector3.forward - toRight - toTop);
		return frustumCorners;
	}

	void Blit(RenderTexture source, RenderTexture destination, Material mat)
	{
		RenderTexture.active = destination;
		mat.SetTexture("_MainTex", source);
		GL.PushMatrix();
		GL.LoadOrtho(); 
		mat.SetPass(0);
		GL.Begin(GL.QUADS);
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 3.0f);
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 2.0f);
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 1.0f);
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);
		GL.End();
		GL.PopMatrix();
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		_Material.SetTexture(_PaintMaskProperty, _PaintMask);
		_Material.SetMatrix(_FrustumProperty, GetFrustumCorners(_Camera));
		_Material.SetMatrix(_CameraInverseProperty, _Camera.cameraToWorldMatrix);
		Blit(source, destination, _Material);
	}

	void Update()
	{
		if (Input.GetMouseButton(0))
		{
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			if (Physics.Raycast(ray, out RaycastHit hit))
			{
				_Material.SetVector(_LastHitPointProperty, _LastHitPoint);
				_Material.SetVector(_HitPointProperty, hit.point);
				_Material.SetVector(_RayOriginProperty, ray.origin);
				_LastHitPoint = hit.point;
			}
		}
	}

	void OnDestroy()
	{
		Destroy(_Material);
	}
}