// https://forum.unity.com/threads/is-it-possible-to-convert-mesh-vertex-colors-to-texture.1087835/#post-7010599
using UnityEngine;
 
public class BakeVertexColorMap : MonoBehaviour
{
    public Mesh SourceMesh;
    public Shader BakeVertexColorMapShader;
    public int Resolution = 2048;
 
    void Start()
    {
        if (SourceMesh != null)
        {
            RenderTexture renderTexture = new RenderTexture(Resolution, Resolution, 0);
            renderTexture.Create();
            Material material = new Material(BakeVertexColorMapShader);
            RenderTexture currentTexture = RenderTexture.active;
            RenderTexture.active = renderTexture;
            GL.Clear(false, true, Color.black, 1.0f);
            material.SetPass(0);
            Graphics.DrawMeshNow(SourceMesh, Vector3.zero, Quaternion.identity);
            Texture2D texture = new Texture2D(Resolution, Resolution, TextureFormat.ARGB32, false);
            texture.ReadPixels( new Rect(0, 0, Resolution, Resolution), 0, 0);
            RenderTexture.active = currentTexture;
            byte[] bytes = texture.EncodeToPNG();
            System.IO.File.WriteAllBytes(System.IO.Path.Combine(Application.dataPath, "VertexColors.png"), bytes);
            Destroy(material);
            Destroy(texture);
            renderTexture.Release();
        }
    }
}