// Sound visualisation.
// Add script with Audio Source to mesh. Play.

using UnityEngine;

public class waveform : MonoBehaviour
{
	public Material material;

	void Update()
	{
		if (Time.frameCount % 10 == 0)
		{
			float[] samples = new float[512];
			AudioListener.GetOutputData(samples, 0);
			material.SetFloatArray("SoundBuffer", samples);
		}
	}
}