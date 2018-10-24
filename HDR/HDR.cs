//Rendering Path: Deferred, Allow HDR=True, Linear Color Space

using System;
using System.Collections.Generic;
using UnityEngine;
			
public class HDR : MonoBehaviour
{
	[Header("External")]
	public Camera MainCamera;
	public ComputeShader HistogramShader;	
	[Header("Bloom settings")]	
	public float intensity = 0.5f;           
	public float threshold = 0.3f;
	public float thresholdLinear
	{
		set { threshold = Mathf.LinearToGammaSpace(value); }
		get { return Mathf.GammaToLinearSpace(threshold); }
	}           
	public float softKnee =0.5f;      
	public float radius = 7.0f;
	public bool antiFlicker = true;       
	[Header("Eye Adaptation settings")]	
	public float lowPercent = 30.0f;
	public float highPercent = 60.0f;
	public float minLuminance = -5.0f;
	public float maxLuminance = 5.0f;
	public float keyValue = 0.4f;
	public bool dynamicKeyValue = true;
	public int adaptationType = 0;
	public float speedUp = 2.0f;
	public float speedDown = 2.0f;
	public int logMin = -14;
	public int logMax = 13;
	
	ComputeBuffer HistogramBuffer;
	HashSet<RenderTexture> m_TemporaryRTs = new HashSet<RenderTexture>();
	RenderTexture[] m_AutoExposurePool = new RenderTexture[2];
	const int k_MaxPyramidBlurLevel = 16;
	RenderTexture[] m_BlurBuffer1 = new RenderTexture[k_MaxPyramidBlurLevel];
	RenderTexture[] m_BlurBuffer2 = new RenderTexture[k_MaxPyramidBlurLevel];	
	int m_AutoExposurePingPing = 0;	
	const int k_HistogramBins = 64;	
	
	void Start()
	{
		MainCamera = GetComponent<Camera>();
		HistogramBuffer = new ComputeBuffer(k_HistogramBins, sizeof(uint));		
	} 
		
	RenderTexture GenerateRT (int w, int h, int d = 0, RenderTextureFormat format = RenderTextureFormat.ARGBHalf)
	{
		var rt = RenderTexture.GetTemporary(w, h, d, format, RenderTextureReadWrite.Default); 
		rt.filterMode = FilterMode.Bilinear;
		rt.wrapMode = TextureWrapMode.Clamp;
		rt.name = "RenderTexture";
		m_TemporaryRTs.Add(rt);
		return rt;
	}

	Texture EyeAdaptation(RenderTexture source, Material uberMaterial)
	{
		uint[] s_EmptyHistogramBuffer;
		const int k_HistogramThreadX = 16;
		const int k_HistogramThreadY = 16;		
		var material = new Material(Shader.Find("Hidden/Post FX/Eye Adaptation"));
		material.shaderKeywords = null;
		s_EmptyHistogramBuffer = new uint[k_HistogramBins];
		float scale = 1f / (logMax - logMin);
		float offset = -logMin * scale;
		var scaleOffsetRes =  new Vector4(scale, offset, Mathf.Floor(MainCamera.pixelWidth / 2f), Mathf.Floor(MainCamera.pixelHeight / 2f));			
		var rt = GenerateRT((int)scaleOffsetRes.z, (int)scaleOffsetRes.w, 0, source.format);
		Graphics.Blit(source, rt);
		if (m_AutoExposurePool[0] == null || !m_AutoExposurePool[0].IsCreated())
			m_AutoExposurePool[0] = new RenderTexture(1, 1, 0, RenderTextureFormat.RFloat);
		if (m_AutoExposurePool[1] == null || !m_AutoExposurePool[1].IsCreated())
			m_AutoExposurePool[1] = new RenderTexture(1, 1, 0, RenderTextureFormat.RFloat);
		HistogramBuffer.SetData(s_EmptyHistogramBuffer);
		int kernel = HistogramShader.FindKernel("KEyeHistogram");
		HistogramShader.SetBuffer(kernel, "_Histogram", HistogramBuffer);
		HistogramShader.SetTexture(kernel, "_Source", rt);
		HistogramShader.SetVector("_ScaleOffsetRes", scaleOffsetRes);
		HistogramShader.Dispatch(kernel, Mathf.CeilToInt(rt.width / (float)k_HistogramThreadX), Mathf.CeilToInt(rt.height / (float)k_HistogramThreadY), 1);
		Release(rt);
		const float minDelta = 1e-2f;
		highPercent = Mathf.Clamp(highPercent, 1f + minDelta, 99f);
		lowPercent = Mathf.Clamp(lowPercent, 1f, highPercent - minDelta);
		material.SetBuffer("_Histogram", HistogramBuffer); 
		float k = 0.69314718055994530941723212145818f;
		material.SetVector("_Params", new Vector4(lowPercent * 0.01f, highPercent * 0.01f, Mathf.Exp(minLuminance * k), Mathf.Exp(maxLuminance * k)));
		material.SetVector("_Speed", new Vector2(speedDown, speedUp));
		material.SetVector("_ScaleOffsetRes", scaleOffsetRes);
		material.SetFloat("_ExposureCompensation", keyValue);
		if (dynamicKeyValue) material.EnableKeyword("AUTO_KEY_VALUE"); 	
		int pp = m_AutoExposurePingPing;
		var src = m_AutoExposurePool[++pp % 2];
		var dst = m_AutoExposurePool[++pp % 2];
		Graphics.Blit(src, dst, material, 0);
		m_AutoExposurePingPing = ++pp % 2;
		RenderTexture m_CurrentAutoExposure = dst;
		return m_CurrentAutoExposure;
	}		
		
	void Bloom(RenderTexture source, Material uberMaterial, Texture autoExposure)
	{
		var material = new Material(Shader.Find("Hidden/Post FX/Bloom"));
		material.shaderKeywords = null;
		material.SetTexture("_AutoExposure", autoExposure);
		var tw = MainCamera.pixelWidth / 2;
		var th = MainCamera.pixelHeight / 2;
		var useRGBM = Application.isMobilePlatform;
		var rtFormat = useRGBM ? RenderTextureFormat.Default : RenderTextureFormat.DefaultHDR;
		float logh = Mathf.Log(th, 2f) + radius - 8f;
		int logh_i = (int)logh;
		int iterations = Mathf.Clamp(logh_i, 1, k_MaxPyramidBlurLevel);
		float lthresh = thresholdLinear;
		material.SetFloat("_Threshold", lthresh);
		float knee = lthresh * softKnee + 1e-5f;
		var curve = new Vector3(lthresh - knee, knee * 2f, 0.25f / knee);
		material.SetVector("_Curve", curve);
		material.SetFloat("_PrefilterOffs", antiFlicker ? -0.5f : 0f);
		float sampleScale = 0.5f + logh - logh_i;
		material.SetFloat("_SampleScale", sampleScale);
		if (antiFlicker) material.EnableKeyword("ANTI_FLICKER");
		var prefiltered = GenerateRT(tw, th, 0, rtFormat);
		Graphics.Blit(source, prefiltered, material, 0);
		var last = prefiltered;
		for (int level = 0; level < iterations; level++)
		{
			m_BlurBuffer1[level] = GenerateRT(last.width / 2, last.height / 2, 0, rtFormat);
			int pass = (level == 0) ? 1 : 2;
			Graphics.Blit(last, m_BlurBuffer1[level], material, pass);
			last = m_BlurBuffer1[level];
		}
		for (int level = iterations - 2; level >= 0; level--)
		{
			var baseTex = m_BlurBuffer1[level];
			material.SetTexture("_BaseTex", baseTex);
			m_BlurBuffer2[level] = GenerateRT(baseTex.width, baseTex.height, 0, rtFormat);
			Graphics.Blit(last, m_BlurBuffer2[level], material, 3);
			last = m_BlurBuffer2[level];
		}
		var bloomTex = last;
		for (int i = 0; i < k_MaxPyramidBlurLevel; i++)
		{
			if (m_BlurBuffer1[i] != null) Release(m_BlurBuffer1[i]);
			if (m_BlurBuffer2[i] != null && m_BlurBuffer2[i] != bloomTex) Release(m_BlurBuffer2[i]);
			m_BlurBuffer1[i] = null;
			m_BlurBuffer2[i] = null;
		}
		Release(prefiltered);
		uberMaterial.SetTexture("_BloomTex", bloomTex);
		uberMaterial.SetVector("_Bloom_Settings", new Vector2(sampleScale, intensity));
		uberMaterial.EnableKeyword("BLOOM");
	}		
			
	void OnRenderImage(RenderTexture src, RenderTexture dst)
	{
		var uberMaterial = new Material(Shader.Find("Hidden/Post FX/Uber Shader"));
		uberMaterial.shaderKeywords = null;
		Texture2D WhiteTexture = new Texture2D(1, 1, TextureFormat.ARGB32, false);
		WhiteTexture.SetPixel(0, 0, new Color(1f, 1f, 1f, 1f));
		WhiteTexture.Apply();
		Texture autoExposure = WhiteTexture;
		autoExposure = EyeAdaptation(src, uberMaterial);          
		uberMaterial.SetTexture("_AutoExposure", autoExposure);
		Bloom(src, uberMaterial, autoExposure);         
		if (!(QualitySettings.activeColorSpace == ColorSpace.Linear))
			uberMaterial.EnableKeyword("UNITY_COLORSPACE_GAMMA");
		Graphics.Blit(src, dst, uberMaterial, 0);
	}

	void Release(RenderTexture rt)
	{
		m_TemporaryRTs.Remove(rt);
		RenderTexture.ReleaseTemporary(rt);
	}
		
	void OnDisable()
	{
		var enumerator = m_TemporaryRTs.GetEnumerator();
		while (enumerator.MoveNext()) RenderTexture.ReleaseTemporary(enumerator.Current);
		m_TemporaryRTs.Clear();
		foreach (var rt in m_AutoExposurePool) Destroy(rt);   
		HistogramBuffer.Release();			
	}
}	