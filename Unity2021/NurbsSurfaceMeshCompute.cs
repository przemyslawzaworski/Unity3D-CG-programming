using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;
 
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class NurbsSurfaceMeshCompute : MonoBehaviour
{
    public ComputeShader NurbsSurfaceCS;
    [Range(1, 1024)] public int TessellationFactor = 64;
    [System.Serializable] public struct ControlPoint {public Transform Transform; public float Weight;};
    [System.Serializable] public struct Vertex {public Vector3 Position; public Vector3 Normal; public Vector4 Tangent; public Vector2 Texcoord;};
    public ControlPoint[] ControlPoints;
 
    private List<Vector4> _ControlPoints = new List<Vector4>();
    private GraphicsBuffer _GraphicsBuffer;
    private Mesh _Mesh;
    private bool _Recalculate = false;
    private int _VertexCount = 0;
 
    void LoadDefaultSettings()
    {
        Vector3[] vectors = new Vector3[]
        {
            new Vector3(00.0f, 00.0f, 00.0f), new Vector3(10.0f, 00.0f, 00.0f), new Vector3(20.0f, 00.0f, 00.0f), new Vector3(30.0f, 00.0f, 00.0f),
            new Vector3(00.0f, 00.0f, 10.0f), new Vector3(10.0f, 10.0f, 10.0f), new Vector3(20.0f, 10.0f, 10.0f), new Vector3(30.0f, 00.0f, 10.0f),
            new Vector3(00.0f, 00.0f, 20.0f), new Vector3(10.0f, 10.0f, 20.0f), new Vector3(20.0f, 10.0f, 20.0f), new Vector3(30.0f, 00.0f, 20.0f),
            new Vector3(00.0f, 00.0f, 30.0f), new Vector3(10.0f, 00.0f, 30.0f), new Vector3(20.0f, 00.0f, 30.0f), new Vector3(30.0f, 00.0f, 30.0f)
        };
        ControlPoints = new ControlPoint[vectors.Length];
        for (int i = 0; i < vectors.Length; i++)
        {
            GameObject element = new GameObject();
            element.name = "ControlPoint" + (i + 1).ToString();
            element.transform.parent = this.transform;
            element.transform.position = vectors[i];
            ControlPoints[i] = new ControlPoint() {Transform = element.transform, Weight = 1.0f};
        }
    }
 
    /* Example for 16 control points (grid 4x4) - fill grid 4x4 into larger collection (max 64)
    HLSL arrays need to have constant (predefined) size, so for another number of control points
    you need to modify a code a bit...
        ########
        ########
        ########
        ########
        ****####
        ****####
        ****####
        ****####
    */
    void LoadDefaultCollection()
    {
        _ControlPoints.Clear();
        _ControlPoints.TrimExcess();
        int index = 0;
        for (int i = 0; i < 64; i++) // max 64 elements, because _ControlPoints[8][8] from compute shader
        {
            if (index > ControlPoints.Length - 1) continue;
            if (i % 8 > 3 || i > 31)
            {
                _ControlPoints.Add(Vector4.zero);
            }
            else
            {
                Vector3 p = ControlPoints[index].Transform.position - this.transform.position;
                _ControlPoints.Add(new Vector4(p.x, p.y, p.z, ControlPoints[index].Weight));
                index++;
            }
        }
    }
 
    void ExportMesh()
    {
        #if UNITY_EDITOR
            Vertex[] points = new Vertex[_Mesh.vertices.Length];
            _GraphicsBuffer.GetData(points);
            Mesh mesh = new Mesh();
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
            List<Vector3> vertices = new List<Vector3>();
            List<int> triangles = new List<int>();
            List<Vector3> normals = new List<Vector3>();
            List<Vector2> uvs = new List<Vector2>();
            List<Vector4> tangents = new List<Vector4>();
            for (int i = 0; i < points.Length; i++)
            {
                vertices.Add(points[i].Position);
                triangles.Add(i);
                normals.Add(points[i].Normal);
                tangents.Add(points[i].Tangent);
                uvs.Add(points[i].Texcoord);
            }
            mesh.vertices = vertices.ToArray();
            mesh.triangles = triangles.ToArray();
            mesh.normals = normals.ToArray();
            mesh.tangents = tangents.ToArray();
            mesh.uv = uvs.ToArray();
            string fileName = System.Guid.NewGuid().ToString("N");
            UnityEditor.AssetDatabase.CreateAsset(mesh, "Assets/" + fileName + ".asset");
            GameObject target = new GameObject();
            target.name = fileName;
            target.AddComponent<MeshFilter>().sharedMesh = mesh;
            MeshRenderer renderer = target.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = UnityEditor.AssetDatabase.GetBuiltinExtraResource<Material>("Default-Material.mat");
            UnityEditor.PrefabUtility.SaveAsPrefabAsset(target, "Assets/" + fileName + ".prefab");
        #endif
    }
 
    void Start()
    {
        #if UNITY_EDITOR
            Material material = this.GetComponent<Renderer>().sharedMaterial;
            if (material == null)
            {
                material = UnityEditor.AssetDatabase.GetBuiltinExtraResource<Material>("Default-Material.mat");
                this.GetComponent<Renderer>().sharedMaterial = material;
            }
        #endif
    }
 
    void Update()
    {
        _VertexCount = TessellationFactor * TessellationFactor * 6;
        if (_Mesh == null || _Recalculate)
        {
            Release();
            _Recalculate = false;
            _Mesh = new Mesh();
            _Mesh.name = "NURBS Surface";
            _Mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
            _Mesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
            VertexAttributeDescriptor[] attributes = new []
            {
                new VertexAttributeDescriptor(VertexAttribute.Position,  VertexAttributeFormat.Float32, 3, stream:0),
                new VertexAttributeDescriptor(VertexAttribute.Normal,    VertexAttributeFormat.Float32, 3, stream:0),
                new VertexAttributeDescriptor(VertexAttribute.Tangent,   VertexAttributeFormat.Float32, 4, stream:0),
                new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2, stream:0),
            };
            _Mesh.SetVertexBufferParams(_VertexCount, attributes);
            _Mesh.SetIndexBufferParams(_VertexCount, IndexFormat.UInt32);
            NativeArray<int> indexBuffer = new NativeArray<int>(_VertexCount, Allocator.Temp);
            for (int i = 0; i < _VertexCount; ++i) indexBuffer[i] = i;
            _Mesh.SetIndexBufferData(indexBuffer, 0, 0, indexBuffer.Length, MeshUpdateFlags.DontRecalculateBounds | MeshUpdateFlags.DontValidateIndices);
            indexBuffer.Dispose();
            SubMeshDescriptor subMeshDescriptor = new SubMeshDescriptor(0, _VertexCount, MeshTopology.Triangles);
            subMeshDescriptor.bounds = new Bounds(Vector3.zero, new Vector3(1e5f, 1e5f, 1e5f));
            _Mesh.SetSubMesh(0, subMeshDescriptor);
            _Mesh.bounds = subMeshDescriptor.bounds;
            GetComponent<MeshFilter>().sharedMesh = _Mesh;
            _GraphicsBuffer = _Mesh.GetVertexBuffer(0);
        }
        LoadDefaultCollection();
        NurbsSurfaceCS.SetInt("_VertexCount", _VertexCount);
        NurbsSurfaceCS.SetInt("_TessellationFactor", TessellationFactor);
        NurbsSurfaceCS.SetBuffer(0, "_GraphicsBuffer", _GraphicsBuffer);
        NurbsSurfaceCS.SetVectorArray("_ControlPoints", _ControlPoints.ToArray());
        NurbsSurfaceCS.GetKernelThreadGroupSizes(0, out uint x, out uint y, out uint z);
        int threadGroupsX = Mathf.Min((_VertexCount + (int)x - 1) / (int)x, 65535);
        int threadGroupsY = (int)y;
        int threadGroupsZ = (int)z;
        NurbsSurfaceCS.Dispatch(0, threadGroupsX, threadGroupsY, threadGroupsZ);
        if (Input.GetKeyDown(KeyCode.R)) LoadDefaultSettings();
        if (Input.GetKeyDown(KeyCode.Space) && (_Mesh != null)) ExportMesh();
    }
 
    void Release()
    {
        if (_Mesh != null) Destroy(_Mesh);
        if (_GraphicsBuffer != null) _GraphicsBuffer.Release();
    }
 
    void OnDestroy()
    {
        Release();
    }
 
    void OnValidate()
    {
        _Recalculate = true;
    }
}