using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogRenderFeature : ScriptableRendererFeature
{
    FogRenderPass fogRenderPass;

    public override void Create()
    {
        //fogRenderPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;// 渲染时机
        // 等价于
        fogRenderPass = new FogRenderPass(RenderPassEvent.BeforeRenderingPostProcessing);
    }

    // 在渲染中插入自定义的fogRenderPass
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        fogRenderPass.Setup(renderer.cameraColorTarget);// 初始化自定义的pass
        renderer.EnqueuePass(fogRenderPass);// 将Pass添加到渲染中
    }
}

public class FogRenderPass : ScriptableRenderPass
{
    static readonly string k_RenderTag = "Render Fog Effects";  // 做标记，我们后续需要在CommandBufferPool中去获取到它，这样的话我们在FrameDebugger中也可以找到它

    // 给属性绑定ID，因为Shader赋值的时候用 ID 会比用字符串快
    static readonly int MainTexId = Shader.PropertyToID("_MainTex");
    static readonly int TempTargetId = Shader.PropertyToID("_TempTargetFog");
    static readonly int FogColorId = Shader.PropertyToID("_FogColor");
    static readonly int SunColorId = Shader.PropertyToID("_SunColor");
    static readonly int HeightFogDensityId = Shader.PropertyToID("_HeightFogDensity");
    static readonly int HeightFogStartId = Shader.PropertyToID("_HeightFogStart");
    static readonly int HeightFogEndId = Shader.PropertyToID("_HeightFogEnd");
    static readonly int HeightFogRangeId = Shader.PropertyToID("_HeightFogRange");

    static readonly int DepthFogDensityId = Shader.PropertyToID("_DepthFogDensity");
    static readonly int DepthFogStartId = Shader.PropertyToID("_DepthFogStart");
    static readonly int DepthFogEndId = Shader.PropertyToID("_DepthFogEnd");
    static readonly int NoiseAmountId = Shader.PropertyToID("_NoiseAmount");

    static readonly int frustumCornersId = Shader.PropertyToID("_FrustumCornersRay");

    FogRender fogRender;
    Material fogMaterial;
    RenderTargetIdentifier currentTarget;
    

    private Matrix4x4 frustumCorners = Matrix4x4.identity;   // 4个角点Ray存于矩阵数据结构中
    public Camera MyCamera = Camera.main;
    public FogRenderPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
        var shader = Shader.Find("GJ/PostEffect/Fog");  // 根据shader路径，初始化shader
        if (shader == null)
        {
            Debug.LogError("Shader not found");
            return;
        }
        fogMaterial = CoreUtils.CreateEngineMaterial(shader);// 根据shader初始化材质
    }

    // 计算4个角点Ray
    public void ConersRayCalculate()
    {
        frustumCorners = Matrix4x4.identity;
        
        float fov = MyCamera.fieldOfView;
        float near = MyCamera.nearClipPlane;
        float far = MyCamera.farClipPlane;
        float aspect = MyCamera.aspect;

        float halfHight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toTop = MyCamera.transform.up * halfHight;
        Vector3 toRight = MyCamera.transform.right * halfHight * aspect;

        Vector3 topLeft = MyCamera.transform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;
        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = MyCamera.transform.forward * near + toTop + toRight;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = MyCamera.transform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = MyCamera.transform.forward * near - toTop + toRight;
        bottomRight.Normalize();
        bottomRight *= scale;

        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);
    }
    // public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    // {
    // }

    // 写一个接口，将currentTarget传进去
    public void Setup(in RenderTargetIdentifier currentTarget)
    {
        this.currentTarget = currentTarget;
    }

    void Render(CommandBuffer cmd, ref RenderingData renderingData)
    {
        

        ref var cameraData = ref renderingData.cameraData;
        var source = currentTarget;         // 当前的RenderTarget用来初始化source
        int destination = TempTargetId;     // 初始化destination（使用临时渲染目标ID）

        // RT长宽初始化
        var w = cameraData.camera.scaledPixelWidth;
        var h = cameraData.camera.scaledPixelHeight;

        // 使用ID设置属性的值
        fogMaterial.SetColor(FogColorId, fogRender.fogColor.value);
        fogMaterial.SetTexture("_RampTexture", fogRender.fogRampColor.value);
        //fogMaterial.SetColor(SunColorId, fogRender.sunColor.value);

        fogMaterial.SetFloat(HeightFogDensityId, fogRender.heightFogDensity.value);
        fogMaterial.SetFloat(HeightFogStartId, fogRender.heightFogStart.value);
        fogMaterial.SetFloat(HeightFogEndId, fogRender.heightFogEnd.value);
        fogMaterial.SetFloat(HeightFogRangeId, fogRender.heightFogRange.value);

        fogMaterial.SetFloat(DepthFogDensityId, fogRender.depthFogDensity.value);
        fogMaterial.SetFloat(DepthFogStartId, fogRender.depthFogStart.value);
        fogMaterial.SetFloat(DepthFogEndId, fogRender.depthFogEnd.value);

        fogMaterial.SetTexture("_NoiseTexture", fogRender.noiseTexture.value);
        fogMaterial.SetFloat(NoiseAmountId, fogRender.noiseAmount.value);
        fogMaterial.SetVector("_Speed", fogRender.speed.value);

        
            
        int DepthFogToggle = 0;
        if(fogRender.depthFog.value)
            DepthFogToggle = 1;
        else{
            DepthFogToggle = 0;
        }
        fogMaterial.SetInt("_DepthFog", DepthFogToggle);

        int HeightFogToggle = 0;
        if(fogRender.heightFog.value)
            HeightFogToggle = 1;
        else{
            HeightFogToggle = 0;
        }
        fogMaterial.SetInt("_HeightFog", HeightFogToggle);

        ConersRayCalculate();//计算角点Ray
        fogMaterial.SetMatrix(frustumCornersId, frustumCorners);

        int shaderPass = 0;
        cmd.SetGlobalTexture(MainTexId, source);// 将后台缓冲区和MainTexID绑定
        cmd.GetTemporaryRT(destination, w, h, 0, FilterMode.Point, RenderTextureFormat.Default);// 申请RenderTexture（包括宽高、深度图、滤波采样模式、RT格式）

        // 后处理操作
        cmd.Blit(source, destination);
        cmd.Blit(destination, source, fogMaterial, shaderPass);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        // 是否创建了材质
        if (fogMaterial == null)
        {
            Debug.LogError("Material not created");
            return;
        }
        // 相机上的后处理开关是否打开
        if (!renderingData.cameraData.postProcessEnabled) return;

        var stack = VolumeManager.instance.stack;// 获得Volume类的堆
        fogRender = stack.GetComponent<FogRender>();// 获得Volume类的实例
        if (fogRender == null) { return; }
        if (!fogRender.IsActive()) { return; }

        var cmd = CommandBufferPool.Get(k_RenderTag);// 拿到CBuffer

        // 渲染核心函数
        Render(cmd, ref renderingData);

        context.ExecuteCommandBuffer(cmd);  // 执行
        CommandBufferPool.Release(cmd); //回收
    }

    
    // public override void OnCameraCleanup(CommandBuffer cmd)
    // {
    // }
}
