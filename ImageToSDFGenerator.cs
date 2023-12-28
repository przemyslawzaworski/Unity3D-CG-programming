using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class ImageToSDFGenerator : MonoBehaviour
{
	[SerializeField] private Collider2D _Collider2D;
	[SerializeField] private int _Resolution = 1024;

	void Start()
	{
		Texture2D texture = new Texture2D(_Resolution, _Resolution, TextureFormat.RFloat, -1, true);
		for (int y = 0; y < texture.height; y++)
		{
			for (int x = 0; x < texture.width; x++)
			{
				Vector2 position = new Vector2(x, y);
				Vector2 closestPoint = _Collider2D.ClosestPoint(position);
				float distance = Vector2.Distance(closestPoint, position);
				texture.SetPixel(x, y, new Color(distance, distance, distance, distance));
			}
		}
		texture.Apply();
		byte[] bytes = ImageConversion.EncodeToEXR(texture, Texture2D.EXRFlags.OutputAsFloat);
		File.WriteAllBytes(Application.dataPath + "/../texture.exr", bytes);
		Object.Destroy(texture);
	}
}