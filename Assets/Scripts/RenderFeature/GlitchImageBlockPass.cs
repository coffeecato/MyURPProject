using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlitchImageBlockPass : ScriptableRenderPass
{
    static class ShaderIDs
    {
        internal static readonly int Params = Shader.PropertyToID("_Params");
        internal static readonly int Params2 = Shader.PropertyToID("_Params2");
        internal static readonly int Params3 = Shader.PropertyToID("_Params3");
    }

    private const string m_ProfilerTag = "Glitch Image Block";
    private Glitch m_Glitch;
    // coffeecat 接入Uber Post
    private RenderTargetIdentifier m_Source;
    private RenderTargetIdentifier m_Destination;

    private Material m_Material;
    private float timeX = 1.0f;

    public GlitchImageBlockPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
    }

    public void Setup(RenderTargetIdentifier source, RenderTargetIdentifier destination, Material mat)
    {
        // coffeecat 接入Uber Post
        m_Source = source;
        m_Destination = destination;
        m_Material = mat;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var stack = VolumeManager.instance.stack;
        m_Glitch = stack.GetComponent<Glitch>();

        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
        bool active = m_Glitch.IsActive();
        if (active)
        {
            timeX += Time.deltaTime;
            if (timeX > 100)
            {
                timeX = 0;
            }

            //Debug.Log("GlitchImagePass Execute-2");
            cmd.SetGlobalTexture("_MainTex", m_Source);
            //Debug.LogFormat("GlitchImagePass Execute-2, speed.value:{0}, amount.value:{1}, fade.value:{2}", m_Glitch.Speed.value, m_Glitch.Amount.value, m_Glitch.Fade.value);
            cmd.SetGlobalVector(ShaderIDs.Params, new Vector3(timeX * m_Glitch.Speed.value, m_Glitch.Amount.value, m_Glitch.Fade.value));
            cmd.SetGlobalVector(ShaderIDs.Params2, new Vector4(m_Glitch.BlockLayer1_U.value, m_Glitch.BlockLayer1_V.value, m_Glitch.BlockLayer2_U.value, m_Glitch.BlockLayer2_V.value));
            cmd.SetGlobalVector(ShaderIDs.Params3, new Vector3(m_Glitch.RGBSplitIndensity.value, m_Glitch.BlockLayer1_Indensity.value, m_Glitch.BlockLayer2_Indensity.value));

            cmd.Blit(m_Source, m_Destination, m_Material);
            //这里设置keyword没有对UberPost生效，为什么？
            //cmd.EnableShaderKeyword("_GLITCH");
        }
        else
        {
            //Debug.Log("GlitchImagePass Execute-3");
            //cmd.DisableShaderKeyword("_GLITCH");
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}