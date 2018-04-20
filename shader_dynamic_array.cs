using UnityEngine;

public class shader_dynamic_array : MonoBehaviour 
{
	[Header("Set material with shader")]
	public Material material;
	[Header("Set coordinates in range [0..1] for points")]	
	public Vector2[] elements;
	
	void Update() 
	{
		int count = elements.Length;
		Texture2D input = new Texture2D (count, 1, TextureFormat.RGBA32, false);
		input.filterMode = FilterMode.Point;
		input.wrapMode = TextureWrapMode.Clamp;
		for (int i=0;i<count;i++)
		{
			input.SetPixel (i,0,new Color (elements[i].x,elements[i].y,0.0f,1.0f));
		}
		input.Apply();
		material.SetTexture("array",input);
		material.SetInt("count",count);		
	}
}