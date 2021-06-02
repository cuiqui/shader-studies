using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshGeneration : MonoBehaviour
{
    [SerializeField] int xSize = 1;
    [SerializeField] int zSize = 1;
    Mesh mesh;
    Vector3[] vertices;
    int[] triangles;

    void Start() {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        CreateShape();
        UpdateMesh();
    }
    private void CreateShape() {
        vertices = new Vector3[(xSize + 1) * (zSize + 1)];

        for (int i = 0, z = 0; z <= zSize; z++) {
            for (int x = 0; x <= xSize; x++) {
                vertices[i] = new Vector3(x, 0, z);
                i++;
            }
        }
        int vert = 0;
        int tris = 0;
        triangles = new int[xSize * zSize * 6];
        for (int z = 0; z < zSize; z++) {
            for(int x = 0; x < xSize; x++) {
                triangles[tris + 0] = vert + 0;
                triangles[tris + 1] = vert + xSize + 1;
                triangles[tris + 2] = vert + 1;
                triangles[tris + 3] = vert + 1;
                triangles[tris + 4] = vert + xSize + 1;
                triangles[tris + 5] = vert + xSize + 2;

                vert++;
                tris += 6;
            }
            vert++;
        }
    }

    private float InverseLerp(float a, float b, float v) {
        return (v - a) / (b - a);
    }

    private Vector2 GetUvForCoords(Vector2 coords) {
        return new Vector2(
            InverseLerp(0, xSize + 1, coords.x),
            InverseLerp(0, zSize + 1, coords.y)
        );
    }

    private Vector2[] CalculateUVs() {
        Vector2[] uvs = new Vector2[(xSize + 1) * (zSize + 1)];
        int i = 0;
        for (int z = 0; z <= zSize; z++) {
            for (int x = 0; x <= xSize; x++) {
                uvs[i] = GetUvForCoords(new Vector2(x, z));
                i++;
            }
        }
        return uvs;
    }

    private void UpdateMesh() {
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
        mesh.uv = CalculateUVs();
        mesh.RecalculateTangents();
    }
}