//Script with shader generate map of trees painted on selected terrain.
//To see results, assign script with material to gameobject and set variables.
//Then create custom render texture,with material unlit,initialization mode realtime,
//source material,set material with shader("map_trees"), update mode realtime.
//Finally, to show content of custom render texture, just set it as input texture
//into any material.
//Written by Przemyslaw Zaworski

using UnityEngine;

public class map_trees : MonoBehaviour 
{
	public Material material;  
	public Terrain terrain;
	RenderTexture A;
	RenderTexture B;
 
	void Start()
	{
		TerrainData terrain_data = terrain.GetComponent<Terrain>().terrainData;
		A = new RenderTexture(1024,1024,0);
		A.Create();  
		B = new RenderTexture(1024,1024,0);
		B.Create();

		foreach(TreeInstance tree in terrain_data.treeInstances)
		{ 
			Vector4 point = new Vector4 (tree.position.x,tree.position.z,0.0f,0.0f);
			material.SetVector("_tree", point);	
			material.SetTexture("_map", A);
			Graphics.Blit(A,B,material);	
			material.SetTexture("_map", B);
			Graphics.Blit(B,A,material);
		}
	}
	
	void OnDestroy()
	{
		A.Release();
		B.Release();
	}
}