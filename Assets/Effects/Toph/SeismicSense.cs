using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SeismicSense : MonoBehaviour
{
    private class Wave
    {
        Vector3 origin;
        Vector2 dist;
        private Color col;

        public Wave(Vector4 origin, float maxDist)
        {
            this.origin = new Vector3(origin.x, origin.y, origin.z);
            col = new Color(origin.x / origin.w, origin.y / origin.w, origin.z / origin.w, 0);
            dist = new Vector2(0, maxDist);
        }

        public bool Update(float speed)
        {
            dist.x += Time.deltaTime * speed;
            return dist.x >= dist.y;
        }

        public Color ToRGBA()
        {
            col.a = dist.x / dist.y;
            return col;
        }
    };

    public float sceneRadius = 50000; // Maximum distance in the scene from the origin
    public float maxWaveDistance = 100;

    // Max num waves = (2 ^ waveMemorySize) ^ 2
    // 2 => 16
    // 3 => 81
    // 4 => 256
    // 5 => 625
    // 6 => 1296
    public int waveMemorySize = 2;
    private int waveMemoryTextureSideLength;
    private int maxNumWaves;

    private int maxActiveWaveIndex = 0;
    private Texture2D waves;
    private List<Wave> activeWaves = new List<Wave>();

    public bool clickToTest = false;

    // Shader
    public Material darkMaterial;
    public float waveSpeed = 5;

    void Start()
    {
        waveMemoryTextureSideLength = 1 << waveMemorySize;
        maxNumWaves = waveMemoryTextureSideLength * waveMemoryTextureSideLength;
        waves = CreateWaveDataTexture(waveMemoryTextureSideLength);

        darkMaterial.SetInt("_WaveTexSideLen", waveMemoryTextureSideLength);
        darkMaterial.SetFloat("_MaxSceneDist", sceneRadius);
        darkMaterial.SetFloat("_MaxWaveDist", maxWaveDistance);
    }

    private void TestAnimation()
    {
        clickToTest = false;
        Vector3 randomPos = Random.onUnitSphere + Vector3.up;
        randomPos.x *= 2; randomPos.z *= 2;
        SpawnWave(randomPos);
    }

    private Texture2D CreateWaveDataTexture(int sideLength)
    {
        return new Texture2D(sideLength, sideLength, TextureFormat.RGBAFloat, false, false)
        {
            filterMode = FilterMode.Point,
            alphaIsTransparency = false
        };
    }

    private void SetPixelForIndex(Texture2D tex, int index, Color color)
    {
        int memX = index % waveMemoryTextureSideLength;
        int memY = index / waveMemoryTextureSideLength;
        tex.SetPixel(memX, memY, color);
    }

    public void SpawnWave(Vector3 origin)
    {

        activeWaves.Add(new Wave(new Vector4(origin.x, origin.y, origin.z, sceneRadius), maxWaveDistance));
    }

    void Update()
    {
        if (clickToTest) TestAnimation();

        for (int i = 0; i < activeWaves.Count; i++) 
        {
            Wave wave = activeWaves[i];
            bool waveDone = wave.Update(waveSpeed);
            if (waveDone)
                activeWaves.RemoveAt(i--);
            else
                SetPixelForIndex(waves, i, activeWaves[i].ToRGBA());
        }

        waves.Apply();

        darkMaterial.SetTexture("_WaveData", waves);

        darkMaterial.SetInt("_MaxWaveIndex", activeWaves.Count);
    }
}
