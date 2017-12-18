//Load buffer.shader into Unity engine
using UnityEngine;

public class buffer : MonoBehaviour 
{
	RenderTexture A;
	RenderTexture B;
	public Material material;	

	void Start() 
	{ 
		A = new RenderTexture(1024,1024,0);
		A.Create();	
		B = new RenderTexture(1024,1024,0);
		B.Create();	
	}
		
	void Update()
	{
		material.SetTexture("MainTex", A);
		Graphics.Blit(A,B,material);
		material.SetTexture("MainTex", B);
		Graphics.Blit(B,A,material);
	}
}