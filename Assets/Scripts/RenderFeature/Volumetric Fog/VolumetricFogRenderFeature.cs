using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricFogRenderFeature : ScriptableRendererFeature
{
    private RenderTargetHandle m_CameraColorAttachment;
    private RenderTargetHandle m_CopyCameraColorAttachment;

    private CopyCameraColorPass m_CopyCameraColorPass;

    public Shader volumetricFogShader;
    private VolumetricFogRenderPass m_VolumetricFogPass;
    private Material m_VolumetricFogMaterial;
    //[SerializeField]
    public Transform cloudTransform;

    //public int _StepCount;

    /// <inheritdoc/>
    public override void Create()
    {
        m_VolumetricFogPass = new VolumetricFogRenderPass(RenderPassEvent.AfterRenderingTransparents);
        m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingTransparents);
        //m_VolumetricFogPass = new VolumetricFogRenderPass(RenderPassEvent.AfterRenderingOpaques);
        //m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingOpaques);

        m_CameraColorAttachment.Init("_CameraColorTexture");
        m_CopyCameraColorAttachment.Init("_CopyCameraColorTexture");

        if (volumetricFogShader != null)
            m_VolumetricFogMaterial = new Material(volumetricFogShader);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (m_VolumetricFogPass.IsEnable())
        {
            m_CopyCameraColorPass.Setup(m_CameraColorAttachment.Identifier(), m_CopyCameraColorAttachment);
            renderer.EnqueuePass(m_CopyCameraColorPass);
        }

        m_VolumetricFogPass.Setup(m_CopyCameraColorAttachment.Identifier(), m_CameraColorAttachment.Identifier(), m_VolumetricFogMaterial, cloudTransform);
        renderer.EnqueuePass(m_VolumetricFogPass);
    }
}


