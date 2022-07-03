using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CopyCameraColorPass : ScriptableRenderPass
{
    // 用于在FrameDebugger中显示名称
    private const string m_ProfilerTag = "Copy Camera Color";

    private RenderTargetIdentifier m_Source;
    private RenderTargetHandle m_Destination;

    public CopyCameraColorPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
    }

    public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
    {
        m_Source = source;
        m_Destination = destination;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        var descriptor = cameraTextureDescriptor;                               // 当前屏幕缓冲的宽高、贴图格式
        descriptor.depthBufferBits = 0;
        cmd.GetTemporaryRT(m_Destination.id, descriptor, FilterMode.Point);     // 通过m_Destination.id关联到_SwitchColorTexture，进而为_SwitchColorTexture申请显存
    }
    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in a performant manner.
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //todo test switch RenderTarget here.
        //Debug.Log("before set camera targetTexture" + (renderingData.cameraData.targetTexture == null));
        //renderingData.cameraData.targetTexture = null;
        //Debug.Log("before set camera targetTexture" + (renderingData.cameraData.targetTexture == null));
    }


    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
        cmd.Blit(m_Source, m_Destination.Identifier());
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        // 如果没有使用申请的RT，则释放
        if (m_Destination != RenderTargetHandle.CameraTarget)
        {
            cmd.ReleaseTemporaryRT(m_Destination.id);           // 对自行分配的显存进行释放
            m_Destination = RenderTargetHandle.CameraTarget;
        }
    }
}
