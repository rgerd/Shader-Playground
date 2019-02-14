using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explosion : MonoBehaviour
{
    Renderer rend;
    Renderer otherRend;
    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
        otherRend = gameObject.transform.GetChild(0).GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        gameObject.transform.RotateAround(Vector3.zero, Vector3.up, Time.deltaTime * 20);
        float timer = Time.time / 2;
        float explosionAmount = Mathf.Sin(timer);
        if (Mathf.Cos(timer) < 0 || Mathf.Sin(timer) < 0)
            explosionAmount = 1;

        rend.sharedMaterial.SetFloat("_CutoffThresh", explosionAmount);
        otherRend.sharedMaterial.SetFloat("_CutoffThresh", explosionAmount);
    }
}
