using UnityEngine;
public class VertexShaderImage : MonoBehaviour
{
    public Shader shader;
    protected Material material;
    void Awake()
    {
        material = new Material(shader);
    }
    void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Triangles, 6 * 1024 * 1024, 1);
    }
}