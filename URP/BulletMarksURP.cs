using UnityEngine;
using System.Runtime.InteropServices;

public class BulletMarksURP : MonoBehaviour
{
	public CapsuleCollider[] Capsules;
	private BulletMark[] _BulletMarks;
	private ComputeBuffer _ComputeBuffer;

	struct BulletMark 
	{
		public Vector3 CapsuleStart;
		public Vector3 CapsuleEnd;
		public float CapsuleRadius;
	}

	void Start()
	{
		_ComputeBuffer = new ComputeBuffer(Capsules.Length, Marshal.SizeOf(typeof(BulletMark)), ComputeBufferType.Default);
		_BulletMarks = new BulletMark[Capsules.Length];
	}

	BulletMark GenerateBulletMark(CapsuleCollider capsule)
	{
		float radius = 0f;
		float height = 0f;
		float scaleX = Mathf.Abs(capsule.transform.lossyScale.x);
		float scaleY = Mathf.Abs(capsule.transform.lossyScale.y);
		float scaleZ = Mathf.Abs(capsule.transform.lossyScale.z);
		Vector3 direction = Vector3.zero;
		switch (capsule.direction)
		{
			case 0:
				radius = Mathf.Max(scaleY, scaleZ) * capsule.radius;
				height = scaleX * capsule.height;
				direction = capsule.transform.TransformDirection(Vector3.right);
				break;
			case 1:
				radius = Mathf.Max(scaleX, scaleZ) * capsule.radius;
				height = scaleY * capsule.height;
				direction = capsule.transform.TransformDirection(Vector3.up);
				break;
			case 2:
				radius = Mathf.Max(scaleX, scaleY) * capsule.radius;
				height = scaleZ * capsule.height;
				direction = capsule.transform.TransformDirection(Vector3.forward);
				break;
		}
		if (height < radius * 2.0f) direction = Vector3.zero;
		Vector3 center = capsule.transform.TransformPoint(capsule.center);
		Vector3 start = center + direction * (height * 0.5f - radius);
		Vector3 end = center - direction * (height * 0.5f - radius);
		return new BulletMark {CapsuleStart = start, CapsuleEnd = end, CapsuleRadius = radius};
	}

	void Update()
	{
		for (int i = 0; i < Capsules.Length; i++)
		{
			_BulletMarks[i] = GenerateBulletMark(Capsules[i]);
		}
		_ComputeBuffer.SetData(_BulletMarks);
		Shader.SetGlobalBuffer("_BulletMarks", _ComputeBuffer);
		Shader.SetGlobalInt("_BulletMarksCount", Capsules.Length);
	}

	void OnDestroy()
	{
		_ComputeBuffer.Release();
	}
}