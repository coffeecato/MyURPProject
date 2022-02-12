using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthTextureTestRenderer : ScriptableRendererFeature
{
    [System.Serializable]
    public class DepthTextureSetting
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Material material = null;
        public string textureId = "_DepthTexture";
    }
    class DepthTextureTestRenderPass : ScriptableRenderPass
    {
        public Material overrideMaterial { get; set; }
        private ShaderTagId m_ShaderTag = new ShaderTagId("UniversalForward");
        private string m_ProfilerTag;
        private RenderTargetHandle m_TemporaryColorTexture;
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }

        public DepthTextureTestRenderPass(string passName, Material mat)
        {
            m_ProfilerTag = passName;
            this.overrideMaterial = mat;
            m_TemporaryColorTexture.Init("temporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier src, RenderTargetHandle dest)
        {
            this.source = src;
            this.destination = dest;
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in an performance manner.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled) return;
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;

            // todo 不能读写同一个颜色target，创建一个临时的render Target去blit
            if (destination == RenderTargetHandle.CameraTarget)
            {
                cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc);
                Blit(cmd, source, m_TemporaryColorTexture.Identifier(), overrideMaterial);
                Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
            }
            else
            {
                Blit(cmd, source, destination.Identifier(), overrideMaterial);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (destination == RenderTargetHandle.CameraTarget)
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }

    public DepthTextureSetting setting = new DepthTextureSetting();
    RenderTargetHandle m_renderTargetHandle;
    DepthTextureTestRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new DepthTextureTestRenderPass("DepthTextureTestRenderer", setting.material);
        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        m_renderTargetHandle.Init(setting.textureId);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        var dest = RenderTargetHandle.CameraTarget;
        m_ScriptablePass.Setup(src, dest);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


