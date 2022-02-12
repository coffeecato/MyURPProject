using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReconstructWorldPosInvMatrix : MonoBehaviour
{
    private Material postEffectMat = null;
    private Camera currentCamera = null;

    private void Awake() {
        currentCamera = GetComponent<Camera>();
    }

    private void OnEnable() {
        if (postEffectMat == null)
            // postEffectMat = new Material(Shader.Find("coffeecat/depth/ReconstructWorldPosInvMatrix"));
            postEffectMat = new Material(Shader.Find("coffeecat/depth/ReconstructWorldPosViewportRay"));
        currentCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnDisable() {
        currentCamera.depthTextureMode &= ~DepthTextureMode.Depth;
    }
}
