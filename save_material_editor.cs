//Put script in Editor directory.

using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(save_material))]
public class save_material_editor : Editor
{
	public override void OnInspectorGUI()
	{
		DrawDefaultInspector();    
		save_material T = (save_material)target;
		if(GUILayout.Button("Reset")) T.ResetBuffer();		
		if(GUILayout.Button("Generate")) T.GenerateImage();
	}
}