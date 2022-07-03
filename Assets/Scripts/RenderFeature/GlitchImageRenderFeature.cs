using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlitchImageRenderFeature : ScriptableRendererFeature
{
    // ������Ļ����RT�ľ��
    private RenderTargetHandle m_CameraColorAttachment;
    private RenderTargetHandle m_CopyCameraColorAttachment;

    // ����CameraColorTexture��pass
    private CopyCameraColorPass m_CopyCameraColorPass;

    // ����Ч��pass
    public Shader glitchImageBlockShader;
    private GlitchImageBlockPass m_GlitchImageBlockPass;
    private Material m_GlitchMaterial;


    /// <inheritdoc/>
    public override void Create()
    {
        m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingTransparents);
        m_GlitchImageBlockPass = new GlitchImageBlockPass(RenderPassEvent.AfterRenderingTransparents);

        // ��ʼ��colorAttachment
        m_CameraColorAttachment.Init("_CameraColorTexture");        // _CameraColorTexture �Ǳ�URPʹ�õ���Ļ��ǰ����ؼ���
        m_CopyCameraColorAttachment.Init("_CopyCameraColorTexture");        // _CopyCameraColorTexture ���Լ�������RT����Ҫ���������Դ�

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

// ���뵽UberPost������ҪBlit CameraColorTexture
//public class GlitchImageRenderFeature : ScriptableRendererFeature
//{
//    // ������Ļ����RT�ľ��
//    //private RenderTargetHandle m_CameraColorAttachment;
//    //private RenderTargetHandle m_CopyCameraColorAttachment;

//    // ����CameraColorTexture��pass
//    //private CopyCameraColorPass m_CopyCameraColorPass;

//    // ����Ч��pass
//    //public Shader glitchImageBlockShader;
//    private GlitchImageBlockPass m_GlitchImageBlockPass;
//    //private Material m_GlitchMaterial;

//    public override void Create()
//    {
//        //Debug.Log("GlitchImageRenderFeature Create");
//        //m_CopyCameraColorPass = new CopyCameraColorPass(RenderPassEvent.AfterRenderingTransparents);
//        m_GlitchImageBlockPass = new GlitchImageBlockPass(RenderPassEvent.AfterRenderingTransparents);

//        //// ��ʼ��colorAttachment
//        //m_CameraColorAttachment.Init("_CameraColorTexture");        // _CameraColorTexture �Ǳ�URPʹ�õ���Ļ��ǰ����ؼ���
//        //m_CopyCameraColorAttachment.Init("_CopyCameraColorTexture");        // _CopyCameraColorTexture ���Լ�������RT����Ҫ���������Դ�

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