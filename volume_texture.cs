//Load volume_texture.shader into Unity Engine.
//Optionially, add fly script to Main Camera.
//This is basic template, so feel free to replace boring hash function with
//own voxel structure.
using UnityEngine;

public class volume_texture : MonoBehaviour 
{
	public Material material;
	public int dimension = 64;
	
	Vector3 hash (Vector3 p)
	{
		float x = p.x*95.43583f+p.y*93.32319f+p.z*94.99343f;
		float y = p.x*35.12345f+p.y*33.51525f+p.z*34.97865f;
		float z = p.x*65.41415f+p.y*63.18549f+p.z*64.17331f;
		Vector3 q = new Vector3(x,y,z);
		float a = Mathf.Abs( (Mathf.Sin( q.x)  * 65536.32f) % 1);
		float b = Mathf.Abs( (Mathf.Sin( q.y)  * 65536.32f) % 1);
		float c = Mathf.Abs( (Mathf.Sin( q.z)  * 65536.32f) % 1);
		return new Vector3 (a,b,c);
	}
	
	void GenerateVolume (int size)
	{
		Texture3D volume = new Texture3D (size, size, size, TextureFormat.ARGB32, true);
		var voxels = new Color[size*size*size];
		int i = 0;
		Color color = Color.black;
		for (int z = 0; z < size; ++z)
		{
			for (int y = 0; y < size; ++y)
			{
				for (int x = 0; x < size; ++x, ++i)
				{
					color.r = hash(new Vector3(x,y,z)).x;
					color.g = hash(new Vector3(x,y,z)).y;
					color.b = hash(new Vector3(x,y,z)).z;
					voxels[i] = color;
				}
			}
		}
		volume.SetPixels (voxels);
		volume.Apply ();
		material.SetTexture("volume",volume);
	}
		
	void Start () 
	{
		GenerateVolume (dimension);
	}	
}
