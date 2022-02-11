using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenDepthScanRenderer : ScriptableRendererFeature
{
    [System.Serializable]
    public class ScreenDepthScanSetting
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Material material = null;
        public string textureId = "_ScreenTexture";
        [Range(0.0f, 1.0f)]
        public float scanValue = 0.05f;
        [Range(0.0f, 0.5f)]
        public float scanLineWidth = 0.02f;
        [Range(0.0f, 10.0f)]
        public float scanLightStrength = 10.0f;
        public Color scanLineColor = Color.white;
    }
    class ScreenDepthScanRenderPass : ScriptableRenderPass
    {
        public Material overrideMaterial { get; set; }
        public int overrideMaterialPassIndex { get; set; }
        // public FilterMode filterMode { get; set; }
        private ShaderTagId m_ShaderTag = new ShaderTagId("UniversalForward");
        // private ScreenDepthScanSetting m_Setting;
        private string m_ProfilerTag;
        private RenderTargetHandle m_TemporaryColorTexture;
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }
        private float scanValue, scanLineWidth, scanLightStrength;
        private Color scanLineColor;
    
        public ScreenDepthScanRenderPass(string passName, RenderPassEvent renderPassEvent, Material mat, float scanValue, float width, float strength, Color color)
        {
            // this.m_Setting = setting;
            m_ProfilerTag = passName;
            this.renderPassEvent = renderPassEvent;
            this.overrideMaterial = mat;
            this.overrideMaterialPassIndex = 0;
            this.scanValue = scanValue;
            this.scanLineWidth = width;
            this.scanLightStrength = strength;
            this.scanLineColor = color;
            m_TemporaryColorTexture.Init("temporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier src, RenderTargetHandle dest)
        {
            this.source = src;
            this.destination = dest;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled) return;
            float lerpValue = Mathf.Min(0.95f, 1 - scanValue);
            if (lerpValue < 0.0005f) lerpValue = 1;
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            
            // todo 不能读写同一个颜色target，创建一个临时的render Target去blit
            if (destination == RenderTargetHandle.CameraTarget)
            {
                cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc);
                overrideMaterial.SetFloat("_ScanValue", lerpValue);
                overrideMaterial.SetFloat("_ScanLineWidth", scanLineWidth);
                overrideMaterial.SetFloat("_ScanLightStrength", scanLightStrength);
                overrideMaterial.SetColor("_ScanLineColor", scanLineColor);
                Blit(cmd, source, m_TemporaryColorTexture.Identifier(), overrideMaterial, overrideMaterialPassIndex);
                Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
            }
            else
            {
                Blit(cmd, source, destination.Identifier(), overrideMaterial, overrideMaterialPassIndex);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (destination == RenderTargetHandle.CameraTarget)
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }

    public ScreenDepthScanSetting setting = new ScreenDepthScanSetting();
    RenderTargetHandle m_renderTargetHandle;
    ScreenDepthScanRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new ScreenDepthScanRenderPass("ScreenDepthScanRender", setting.renderPassEvent, setting.material, setting.scanValue, setting.scanLineWidth, setting.scanLightStrength, setting.scanLineColor);
        m_renderTargetHandle.Init(setting.textureId);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        // var dest = (setting.destination == Target.Color) ? RenderTargetHandle.CameraTarget : m_renderTargetHandle;
        var dest = RenderTargetHandle.CameraTarget;
        // var dest = m_renderTargetHandle;
        if(setting.material == null)
        {
            Debug.Log("材质丢失");
            return;
        }
        m_ScriptablePass.Setup(src, dest);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


