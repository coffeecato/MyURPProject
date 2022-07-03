using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlitchImageRenderFeature : ScriptableRendererFeature
{
    // 持有屏幕缓冲RT的句柄
    private RenderTargetHandle m_CameraColorAttachment;
    private RenderTargetHandle m_CopyCameraColorAttachment;

    // 拷贝CameraColorTexture的pass
    private CopyCameraColorPass m_CopyCameraColorPass;

    // 故障效果pass
    public Shader glitchImageBlockShader;
    private GlitchImageBlockPass m_GlitchImageBlockPass;
    private Material m_GlitchMaterial;


    /// <inheritdoc/>
    public override void Create()
    {
        m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingTransparents);
        m_GlitchImageBlockPass = new GlitchImageBlockPass(RenderPassEvent.AfterRenderingTransparents);

        // 初始化colorAttachment
        m_CameraColorAttachment.Init("_CameraColorTexture");        // _CameraColorTexture 是被URP使用的屏幕当前纹理关键字
        m_CopyCameraColorAttachment.Init("_CopyCameraColorTexture");        // _CopyCameraColorTexture 是自己创建的RT，需要自行申请显存

        if (glitchImageBlockShader != null)
            m_GlitchMaterial = new Material(glitchImageBlockShader);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_CopyCameraColorPass.Setup(m_CameraColorAttachment.Identifier(), m_CopyCameraColorAttachment);
        renderer.EnqueuePass(m_CopyCameraColorPass);

        m_GlitchImageBlockPass.Setup(m_CopyCameraColorAttachment.Identifier(), m_CameraColorAttachment.Identifier(), m_GlitchMaterial);
        renderer.EnqueuePass(m_GlitchImageBlockPass);
    }
}

// 接入到UberPost，不需要Blit CameraColorTexture
//public class GlitchImageRenderFeature : ScriptableRendererFeature
//{
//    // 持有屏幕缓冲RT的句柄
//    //private RenderTargetHandle m_CameraColorAttachment;
//    //private RenderTargetHandle m_CopyCameraColorAttachment;

//    // 拷贝CameraColorTexture的pass
//    //private CopyCameraColorPass m_CopyCameraColorPass;

//    // 故障效果pass
//    //public Shader glitchImageBlockShader;
//    private GlitchImageBlockPass m_GlitchImageBlockPass;
//    //private Material m_GlitchMaterial;

//    public override void Create()
//    {
//        //Debug.Log("GlitchImageRenderFeature Create");
//        //m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingTransparents);
//        m_GlitchImageBlockPass = new GlitchImageBlockPass(RenderPassEvent.AfterRenderingTransparents);

//        //// 初始化colorAttachment
//        //m_CameraColorAttachment.Init("_CameraColorTexture");        // _CameraColorTexture 是被URP使用的屏幕当前纹理关键字
//        //m_CopyCameraColorAttachment.Init("_CopyCameraColorTexture");        // _CopyCameraColorTexture 是自己创建的RT，需要自行申请显存

//        //if (glitchImageBlockShader != null)
//        //    m_GlitchMaterial = new Material(glitchImageBlockShader);
//    }

//    // Here you can inject one or multiple render passes in the renderer.
//    // This method is called when setting up the renderer once per-camera.
//    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
//    {
//        //m_CopyCameraColorPass.Setup(m_CameraColorAttachment.Identifier(), m_CopyCameraColorAttachment);
//        //renderer.EnqueuePass(m_CopyCameraColorPass);

//        //m_GlitchImageBlockPass.Setup(m_CopyCameraColorAttachment.Identifier(), m_CameraColorAttachment.Identifier(), m_GlitchMaterial);
//        renderer.EnqueuePass(m_GlitchImageBlockPass);
//    }
//}