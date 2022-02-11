using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ScreenDepthScan : MonoBehaviour
{
    private Material postEffectMat = null;
    private Camera currentCam = null;
    [Range(0.0f, 1.0f)]
    public float scanValue = 0.05f;
    [Range(0.0f, 0.5f)]
    public float scanLineWidth = 0.02f;
    [Range(0.0f, 10.0f)]
    public float scanLightStrength = 10.0f;
    public Color scanLineColor = Color.white;
        
    private void Awake() {
        currentCam = GetComponent<Camera>();
    }
    private void OnEnable() {
        if (postEffectMat == null){
            postEffectMat = new Material(Shader.Find("coffeecat/depth/ScreenDepthScan"));
        }
        currentCam.depthTextureMode |= DepthTextureMode.Depth;
    }
    private void OnDisable() {
        currentCam.depthTextureMode &= ~DepthTextureMode.Depth;
    }
    // private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        
    // }
}
