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
    private Transform m_CloudTrans;
    //public int _StepCount;
    private Vector3 boundsMin, boundsMax;

    public VolumetricFogRenderPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
    }

    // 用于 active == false 时，避免添加 pass 到渲染队列。
    public bool IsEnable() { return VolumeManager.instance.stack.GetComponent<VolumetricFog>().IsActive(); }

    public void Setup(RenderTargetIdentifier source, RenderTargetIdentifier desination, Material mat, Transform trans)
    {
        m_Source = source;
        m_Destination = desination;
        m_Material = mat;
        m_CloudTrans = trans;
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
            if (m_CloudTrans != null)
            {
                boundsMin = m_CloudTrans.position - m_CloudTrans.localScale / 2;
                boundsMax = m_CloudTrans.position + m_CloudTrans.localScale / 2;
                Debug.LogFormat("boundsMin = {0}, boundsMax = {1}", boundsMin.ToString(), boundsMax.ToString());
                cmd.SetGlobalVector("_boundsMin", boundsMin);
                cmd.SetGlobalVector("_boundsMax", boundsMax);
            }
            cmd.SetGlobalFloat("_StepCount", m_VolumetricFog.StepCount.value);
            //cmd.SetGlobalFloat("_StepCount", _StepCount);
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