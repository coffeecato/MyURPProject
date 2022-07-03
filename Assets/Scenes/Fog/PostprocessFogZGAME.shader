// https://blog.csdn.net/coffeecato
// 2022.0302
// 实现高度雾&深度雾（通过射线法重建世界坐标）
Shader "coffeecat/fog/PostprocessFogZGAME"
{
    Properties
    {
        _DepthRampTex ("深度渐变纹理", 2D) = "white"{}
        _HeightRampTex ("高度渐变纹理", 2D) = "white"{}
        _FogColor ("雾的颜色", Color) = (0.5, 0.5, 0.5, 1)

        [Toggle] _OpenHeight ("开启高度雾", Float) = 1
        _FogHeight ("雾的浓度", Float) = 15                            // 与下面的参数结合起来控制高度雾
        _WorldFogHeight ("自上而下的高度", Float) = 10                 // 自上而下的雾效高度
        
        [Toggle] _OpenDepth ("开启深度雾", Float) = 1
        _FogDepthScale ("迷雾深度系数", Float) = 1

        _NoiseTex ("噪声纹理", 2D) = "white"{}
        _WorldPosScale ("noise 缩放系数", Range(0, 0.1)) = 0.05
        _NoiseSpX ("Noise Speed X", Range(-1, 1)) = 1                   // 雾流动方向
        _NoiseSpY ("Noise Speed Y", Range(-1, 1)) = 1
        _HeightNoiseScale ("HeightNoiseScale", Range(1, 10)) = 1
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    TEXTURE2D(_DepthRampTex); SAMPLER(sampler_DepthRampTex);
    TEXTURE2D(_HeightRampTex); SAMPLER(sampler_HeightRampTex);
    TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    
    float _FogHeight, _WorldFogHeight, _WorldPosScale, _NoiseSpX, _NoiseSpY, _HeightNoiseScale, _FogDepthScale, _OpenHeight, _OpenDepth;
    half4 _FogColor;

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float3 viewRayWorld : TEXCOORD1;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = v.uv;
        float depth = 1;
        #if UNITY_REVERSED_Z
            depth = 1 - depth;
        #endif
        float3 worldPos = ComputeWorldSpacePosition(v.uv, depth, UNITY_MATRIX_I_VP);
        o.viewRayWorld = worldPos - _WorldSpaceCameraPos.xyz;

        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        #if UNITY_REVERSED_Z != 1
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        #endif
        depth = Linear01Depth(depth, _ZBufferParams);
        float3 worldPos = _WorldSpaceCameraPos.xyz + depth * i.viewRayWorld;

        // half4 mainTex = SAMPLE_TEXTURE2D(_DepthRampTex, sampler_DepthRampTex, i.uv);
        // 噪声模拟流动
        float2 noiseUV = worldPos.xz * _WorldPosScale + _Time.y * half2(_NoiseSpX, _NoiseSpY);
        float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
        
        // 计算雾效影响因子
        float factor = 1;
        half4 heightColor = 1;
        half4 fogColor = _FogColor;
        if (_OpenHeight == 1)
        {
            // factor = (_WorldFogHeight - worldPos.y - noise * _HeightNoiseScale) / (_WorldFogHeight - _FogHeight);    
            // 感觉翻转过来的效果好一点，雾覆盖在物体之上
            factor = (_WorldFogHeight - worldPos.y - noise * _HeightNoiseScale) / (_FogHeight - _WorldFogHeight);
            heightColor = SAMPLE_TEXTURE2D(_HeightRampTex, sampler_HeightRampTex, noiseUV);
            fogColor = lerp(fogColor, heightColor, factor);
        }
        half4 depthColor = 1;
        if (_OpenDepth == 1)
        {
            factor = max(depth * _FogDepthScale * (1 - noise), factor);
            depthColor = SAMPLE_TEXTURE2D(_DepthRampTex, sampler_DepthRampTex, noiseUV);
            fogColor = lerp(fogColor, depthColor, factor);
        }
        factor = saturate(factor);

        fogColor = lerp(fogColor, _FogColor, _FogColor.a);
        half4 color = lerp(_FogColor, fogColor, factor);
        // half4 color = lerp(fogColor, _FogColor, factor);

        return color;
    }
    ENDHLSL

    SubShader
    {
        Tags { "LightMode" = "UniversalForward" }
        ZTest Off Cull Off ZWrite Off
        // Blend One OneMinusSrcAlpha           // 【？】雾效会覆盖不透明物体的颜色
        // Blend SrcAlpha OneMinusSrcAlpha      // 试验一下能否解决上面的问题

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
