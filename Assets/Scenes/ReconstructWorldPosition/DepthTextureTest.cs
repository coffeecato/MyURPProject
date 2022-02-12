using UnityEngine;
[ExecuteInEditMode]
public class DepthTextureTest : MonoBehaviour
{
    private Material postEffectMat = null;
    private Camera currentCamera = null;

    private void Awake() {
        currentCamera = GetComponent<Camera>();
    }

    private void OnEnable() {
        if (postEffectMat == null)
            postEffectMat = new Material(Shader.Find("coffeecat/depth/DepthTextureTest"));
        currentCamera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnDisable() {
        currentCamera.depthTextureMode &= ~DepthTextureMode.Depth;
    }

    
}
