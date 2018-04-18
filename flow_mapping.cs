using UnityEngine;

public class flow_mapping : MonoBehaviour 
{
	public Material material;

	float FlowMapOffset0;
	float FlowMapOffset1;
	
	void Start () 
	{
		FlowMapOffset0 = 0.000f;
		FlowMapOffset1 = 0.075f;
	}
	
	void Update () 
	{
		FlowMapOffset0 += 0.05f * Time.deltaTime;
		FlowMapOffset1 += 0.05f * Time.deltaTime;
		if ( FlowMapOffset0 >= 0.15f ) FlowMapOffset0 = 0.0f;
		if ( FlowMapOffset1 >= 0.15f ) FlowMapOffset1 = 0.0f;
		material.SetFloat("FlowMapOffset0",FlowMapOffset0);
		material.SetFloat("FlowMapOffset1",FlowMapOffset1);
	}
}
