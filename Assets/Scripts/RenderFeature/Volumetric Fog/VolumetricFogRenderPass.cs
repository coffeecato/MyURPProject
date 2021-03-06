using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class VolumetricFogRenderPass : ScriptableRenderPass
{
    private const string m_ProfilerTag = "Volume Fog";
    private VolumetricFog m_VolumetricFog;
    private RenderTargetIdentifier m_Source;
    private RenderTargetIdentifier m_Destination;

    private Material m_Material;

    public VolumetricFogRenderPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
    }

    public void Setup(RenderTargetIdentifier source, RenderTargetIdentifier desination, Material mat)
    {
        m_Source = source;
        m_Destination = desination;
        m_Material = mat;
    }
    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in a performant manner.
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var stack = VolumeManager.instance.stack;
        m_VolumetricFog = stack.GetComponent<VolumetricFog>();

        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
        bool active = m_VolumetricFog.IsActive();
        if (active)
        {
            cmd.SetGlobalTexture("_MainTex", m_Source);
            cmd.Blit(m_Source, m_Destination, m_Material);
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}