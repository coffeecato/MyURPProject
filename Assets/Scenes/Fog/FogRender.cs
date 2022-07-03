using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogRender : VolumeComponent, IPostProcessComponent
{
    [Header("雾效开关(打开开启雾效，两个都打开为两种雾效叠加)")]
    public BoolParameter depthFog = new BoolParameter(false);
    public BoolParameter heightFog = new BoolParameter(false);
    
    
    private static Texture fogRamptexture = null;
    [Space(20)]
    [Header("雾效颜色")]
    public ColorParameter fogColor = new ColorParameter(Color.white);
    public TextureParameter fogRampColor = new TextureParameter(fogRamptexture);
    //public ColorParameter sunColor = new ColorParameter(Color.yellow);
    [Space(20)]

    [Header("DepthFog 深度雾参数")]
    public FloatParameter depthFogDensity = new FloatParameter(1.0f);
    public FloatParameter depthFogStart = new FloatParameter(0.0f);
    public FloatParameter depthFogEnd = new FloatParameter(2.0f);
    [Space(20)]

    [Header("HeightFog 高度雾参数")]
    public FloatParameter heightFogDensity = new FloatParameter(0.01f);
    public FloatParameter heightFogStart = new FloatParameter(1.3f);
    public FloatParameter heightFogEnd = new FloatParameter(2.5f);
    public FloatParameter heightFogRange = new FloatParameter(100.0f);
    

    
    private static Texture fogNoiseTexture = null;
    [Space(20)]
    [Header("使用噪波纹理")]
    public TextureParameter noiseTexture = new TextureParameter(fogNoiseTexture);
    public FloatParameter noiseAmount = new FloatParameter(1.0f);
    [Space(20)]

    [Header("雾飘动速度（需要使用噪波纹理）")]
    public Vector2Parameter speed = new Vector2Parameter(new Vector2(0.01f, 0.0f));
    
    public bool IsActive() => depthFogDensity.value > 0.0f;

    public bool IsTileCompatible() => false;
}