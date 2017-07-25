//source: https://github.com/brianasu/unity-ray-marching/tree/volumetric-textures
//Add script to Main Camera. 
//Create Cube with scale (4,4,4), position(0) and rotation(0). Assign to cube material with Volume.shader
//For generate volume texture, you can use for example dataset from http://froggy.lbl.gov/images/whole.frog/data/MRI/tiff/
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class RayMarching : MonoBehaviour
{
	[SerializeField]
	private Shader compositeShader;
	[SerializeField]
	private Shader renderFrontDepthShader;
	[SerializeField]
	private Shader renderBackDepthShader;
	[SerializeField]
	private Shader rayMarchShader;
	[Header("Drag all the textures in here")]
	[SerializeField]
	private Texture2D[] slices;
	[Header("Volume texture size. These must be a power of 2")]
	[SerializeField]
	private int volumeWidth = 256;
	[SerializeField]
	private int volumeHeight = 256;
	[SerializeField]
	private int volumeDepth = 256;
	[Header("Clipping planes percentage")]
	[SerializeField]
	private Vector4 clipDimensions = new Vector4(100, 100, 100, 0);

	private Material _rayMarchMaterial;
	private Material _compositeMaterial;
	private Camera _ppCamera;
	private Texture3D _volumeBuffer;

	private void Start()
	{
		_rayMarchMaterial = new Material(rayMarchShader);
		_compositeMaterial = new Material(compositeShader);
		GenerateVolumeTexture();
	}

	private void OnDestroy()
	{
		if(_volumeBuffer != null)
		{
			Destroy(_volumeBuffer);
		}
	}
	
	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		_rayMarchMaterial.SetTexture("_VolumeTex", _volumeBuffer);
		var width = source.width ;
		var height = source.height ;
		if(_ppCamera == null)
		{
			var go = new GameObject("PPCamera");
			_ppCamera = go.AddComponent<Camera>();
			_ppCamera.enabled = false;
		}
		_ppCamera.CopyFrom(GetComponent<Camera>());
		_ppCamera.clearFlags = CameraClearFlags.SolidColor;
		_ppCamera.backgroundColor = Color.white;
		var frontDepth = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		var backDepth = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		var volumeTarget = RenderTexture.GetTemporary(width, height, 0);
		_ppCamera.targetTexture = frontDepth;
		_ppCamera.RenderWithShader(renderFrontDepthShader, "RenderType");
		_ppCamera.targetTexture = backDepth;
		_ppCamera.RenderWithShader(renderBackDepthShader, "RenderType");
		_rayMarchMaterial.SetTexture("_FrontTex", frontDepth);
		_rayMarchMaterial.SetTexture("_BackTex", backDepth);
		_rayMarchMaterial.SetVector("_ClipDims", clipDimensions / 100f); 
		Graphics.Blit(null, volumeTarget, _rayMarchMaterial);
		_compositeMaterial.SetTexture("_BlendTex", volumeTarget);
		Graphics.Blit(source, destination, _compositeMaterial);
		RenderTexture.ReleaseTemporary(volumeTarget);
		RenderTexture.ReleaseTemporary(frontDepth);
		RenderTexture.ReleaseTemporary(backDepth);
	}

	private void GenerateVolumeTexture()
	{
		System.Array.Sort(slices, (x, y) => x.name.CompareTo(y.name));
		_volumeBuffer = new Texture3D(volumeWidth, volumeHeight, volumeDepth, TextureFormat.ARGB32, false);		
		int w = _volumeBuffer.width;
		int h = _volumeBuffer.height;
		int d = _volumeBuffer.depth;
		var countOffset = (slices.Length - 1) / (float)d;		
		var volumeColors = new Color[w * h * d];		
		var sliceCount = 0;
		var sliceCountFloat = 0f;
		for(int z = 0; z < d; z++)
		{
			sliceCountFloat += countOffset;
			sliceCount = Mathf.FloorToInt(sliceCountFloat);
			for(int x = 0; x < w; x++)
			{
				for(int y = 0; y < h; y++)
				{
					var idx = x + (y * w) + (z * (w * h));
					volumeColors[idx] = slices[sliceCount].GetPixelBilinear(x / (float)w, y / (float)h); 
					volumeColors[idx].a *= volumeColors[idx].r;
				}
			}
		}
		
		_volumeBuffer.SetPixels(volumeColors);
		_volumeBuffer.Apply();		
		_rayMarchMaterial.SetTexture("_VolumeTex", _volumeBuffer);
	}
}
