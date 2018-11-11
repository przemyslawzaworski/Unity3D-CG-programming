// Put in Editor directory.
using UnityEngine;
using UnityEditor;

public class GenerateVolumeTexture : EditorWindow
{	
	Transform Cage;
	int size = 128;
	string filename = "noname.bin";
	
	[MenuItem("Assets/Generate Volume Texture")]
	static void ShowWindow () 
	{
		EditorWindow.GetWindow ( typeof(GenerateVolumeTexture));
	}

	void SaveFloatArrayToFile(float[] x, string path)
	{
		byte[] a = new byte[x.Length * 4];
		System.Buffer.BlockCopy(x, 0, a, 0, a.Length);
		System.IO.File.WriteAllBytes(path,a);
	}

	void OnGUI()
	{
		Cage = EditorGUILayout.ObjectField("Cage", Cage, typeof(Transform), true) as Transform;	
		size = EditorGUILayout.IntField("Volume dimension:", size);
		filename = EditorGUILayout.TextField("File name: ", filename);		
		if ( GUILayout.Button( "Make" ) ) GenerateVolume ();
	} 
		
	void GenerateVolume ()
	{
		float[] voxels = new float[size*size*size];
		int i = 0;
		float s = 1.0f/size;
		Vector3 p = Cage.position;
		Vector3 o = new Vector3(p.x-0.5f,p.y-0.5f,p.z-0.5f);
		for (int z = 0; z < size; ++z)
		{
			for (int y = 0; y < size; ++y)
			{
				for (int x = 0; x < size; ++x, ++i)
				{
					if (Physics.CheckSphere(new Vector3(s*x+o.x,s*y+o.y,s*z+o.z), s*0.5f))
						voxels[i] = 0.9f;
					else 
						voxels[i] = 0.0f;
				}
			}
		}
		SaveFloatArrayToFile(voxels, Application.dataPath + "/StreamingAssets/" + filename);
	}
}