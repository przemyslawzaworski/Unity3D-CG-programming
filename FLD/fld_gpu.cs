using UnityEngine;
using System.Collections;
using System;
using System.IO;
using System.Linq;

public class fld_gpu : MonoBehaviour 
{
	public ComputeShader computeshader;

	void Start () 
	{
		StreamReader file1 = new StreamReader ("C:\\acer.txt");  
		StreamReader file2 = new StreamReader ("C:\\quercus.txt");
		float[,] Acer = new float[176, 64];
		float[,] Quercus = new float[608,64] ;
		float[] Fisher = new float[64];

		for (int n = 0; n < 176; n++) //read file data
		{
			for (int nn = 0; nn <64; nn++) 
			{				
				Acer [n, nn] =  Convert.ToSingle (file1.ReadLine());
			}
		}
		for (int n = 0; n < 608; n++) //read file data
		{
			for (int nn = 0; nn < 64; nn++) 
			{
				Quercus [n, nn] = Convert.ToSingle (file2.ReadLine ());
			}
		} 
		file1.Close (); //close file
		file2.Close ();

		float poczatek = Time.realtimeSinceStartup;  
		ComputeBuffer acer = new ComputeBuffer (176 * 64, sizeof(float));  
		ComputeBuffer quercus = new ComputeBuffer (608 * 64, sizeof(float));
		ComputeBuffer fisher = new ComputeBuffer (64, sizeof(float));
		computeshader.SetBuffer (0, "acer", acer);  
		computeshader.SetBuffer (0, "quercus", quercus);
		computeshader.SetBuffer (0, "fisher", fisher);
		acer.SetData (Acer);   
		quercus.SetData (Quercus);

		computeshader.Dispatch (0, 1, 1, 1);  //run smpd_gpu.compute

		fisher.GetData (Fisher); 
		acer.Release ();  
		quercus.Release ();
		fisher.Release();
		float koniec = Time.realtimeSinceStartup - poczatek; 

		Debug.Log ("FS winner:  "+Array.IndexOf (Fisher, Fisher.Max ()));
		Debug.Log ("FLD value:  "+Fisher.Max ());
		Debug.Log ("Wykonanie skryptu trwało: "+String.Format( "{0:0.000000}",koniec)+"  sekund.");
	}		
}
