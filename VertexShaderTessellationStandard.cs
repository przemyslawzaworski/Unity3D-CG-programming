using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using System.Runtime.InteropServices;

public class VertexShaderTessellationStandard : MonoBehaviour
{
	public Mesh BaseMesh;
	public Shader TessellationShader;
	[Range(1, 1024)] public int TessellationFactor = 5;
	[Range(0f,0.5f)] public float Phong = 0.0f;
	public CullMode CullMode = CullMode.Off;

	GraphicsBuffer _VertexBuffer, _IndexBuffer;
	ComputeBuffer _ConstantBuffer;
	Bounds _Bounds;
	Material _Material;
	int _VertexCount = 0, _Dimension = 0;

	struct Element
	{
		public int VertexOffset;
		public int NormalOffset;
		public int TangentOffset;
		public int ColorOffset;
		public int Texcoord0Offset;
		public int Texcoord1Offset;
		public int Texcoord2Offset;
		public int Texcoord3Offset;
	}

	void Start()
	{
		BaseMesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
		BaseMesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
		_VertexBuffer = BaseMesh.GetVertexBuffer(0);
		_IndexBuffer = BaseMesh.GetIndexBuffer();
		_ConstantBuffer = new ComputeBuffer(1, Marshal.SizeOf(typeof(Element)), ComputeBufferType.Constant);
		_Bounds = BaseMesh.bounds;
		_Material = new Material(TessellationShader);
		VertexAttributeDescriptor[] attributes = BaseMesh.GetVertexAttributes();
		Element element = new Element();
		for (int i = 0; i < attributes.Length; i++) 
		{
			if (attributes[i].attribute == VertexAttribute.Position) element.VertexOffset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.Normal) element.NormalOffset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.Tangent) element.TangentOffset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.Color) element.ColorOffset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.TexCoord0) element.Texcoord0Offset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.TexCoord1) element.Texcoord1Offset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.TexCoord2) element.Texcoord2Offset = _Dimension;
			if (attributes[i].attribute == VertexAttribute.TexCoord3) element.Texcoord3Offset = _Dimension;
			_Dimension += attributes[i].dimension;
		}
		_ConstantBuffer.SetData(new Element[]{element});
	}

	void Update()
	{
		_Material.SetBuffer("_VertexBuffer", _VertexBuffer);
		_Material.SetBuffer("_IndexBuffer", _IndexBuffer);
		_Material.SetConstantBuffer("_ConstantBuffer", _ConstantBuffer, 0, Marshal.SizeOf(typeof(Element)));
		_Material.SetInt("_TessellationFactor", TessellationFactor);
		_Material.SetInt("_CullMode", (int)CullMode);
		_Material.SetInt("_Dimension", _Dimension);
		_Material.SetFloat("_Phong", Phong);
		_VertexCount = TessellationFactor * TessellationFactor * _IndexBuffer.count;
		Graphics.DrawProcedural(_Material, _Bounds, MeshTopology.Triangles, _VertexCount, 1, null, null, ShadowCastingMode.On, true, gameObject.layer);
	}

	void OnGUI()
	{
		GUI.Label(new Rect(10, 10, 200, 30), "Vertex Count: " + _VertexCount.ToString());
	}

	void OnDestroy()
	{
		_VertexBuffer.Release();
		_IndexBuffer.Release();
		_ConstantBuffer.Release();
		Destroy(_Material);
	}
}