using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class outline : MonoBehaviour 
{
	public GameObject[] game_object;
	
	void Update () 
	{
		RaycastHit hit; 
		Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition); 
		if ( Physics.Raycast (ray,out hit,100.0f)) 
		{
			for (int i=0;i<game_object.Length;i++)
			{
				if (hit.transform.gameObject.name==game_object[i].name)
				{
					game_object[i].GetComponent<Renderer>().material.SetFloat("_enable",1.0f);
				}
				else
				{
					game_object[i].GetComponent<Renderer>().material.SetFloat("_enable",0.0f);					
				}
			}
		}
		else
		{
			for (int i=0;i<game_object.Length;i++)
			{
				game_object[i].GetComponent<Renderer>().material.SetFloat("_enable",0.0f);					
			}			
		}
	}
}
