// https://blog.csdn.net/coffeecato
// 2022.0302
// 实现高度雾&深度雾，参考其他项目写法
Shader "coffeecat/fog/HeightFogOptimize_backup"
{
    Properties
    {
        _MainTex ("Base", 2D) = "white"{}
        _FogColor ("Fog Color", Color) = (0.5, 0.5, 0.5, 1)

        [Toggle] _OpenHeight ("开启高度雾", Float) = 1
        _FogHeightDensity ("高度雾强度", Float) = 1
        _FogHeightBegin ("高度雾起点", Float) = 0
        _FogHeightEnd ("高度雾终点", Float) = 0
        _FogHeightRange ("高度雾范围", Float) = 0
        
        [Toggle] _OpenDepth ("开启深度雾", Float) = 1
        _FogDepthDensity ("深度雾强度", Float) = 1
        _FogDepthBegin ("深度雾起点", Float) = 0
        _FogDepthEnd ("深度雾终点", Float) = 0

        // _NoiseTex ("噪声纹理", 2D) = "white"{}
        _NoiseTex ("噪声纹理", 2D) = "black"{}
        _WorldPosScale ("WorldPosScale", Range(0, 0.1)) = 0.05
        _NoiseSpX ("Noise Speed X", Range(0, 1)) = 1
        _NoiseSpY ("Noise Speed Y", Range(0, 1)) = 1
        _NoiseScale ("HeightNoiseScale", Range(1, 10)) = 1
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
    TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    float _FogHeight, _WorldFogHeight, _WorldPosScale, _NoiseSpX, _NoiseSpY, _NoiseScale, _FogDepthScale, _OpenHeight, _OpenDepth;
    float _FogHeightDensity, _FogHeightBegin, _FogHeightEnd, _FogHeightRange;
    float _FogDepthDensity, _FogDepthBegin, _FogDepthEnd;
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
        // depth = LinearEyeDepth(depth, _ZBufferParams);
        float3 worldPos = _WorldSpaceCameraPos.xyz + depth * i.viewRayWorld;
        float3 viewWS = depth * i.viewRayWorld;

        half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        // 噪声模拟流动
        float2 noiseUV = worldPos.xz * _WorldPosScale + _Time.y * half2(_NoiseSpX, _NoiseSpY);
        float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;

        float heightDensity = (_FogHeightEnd - worldPos.y + _FogHeightRange) / (_FogHeightEnd - _FogHeightBegin);
        heightDensity = saturate(heightDensity * _FogHeightDensity);

        // float depthDensity = (_FogDepthEnd - viewWS.z) / (_FogDepthEnd - _FogDepthBegin);
        float depthDensity = (_FogDepthEnd - worldPos.z) / (_FogDepthEnd - _FogDepthBegin);
        depthDensity = saturate(depthDensity * _FogDepthDensity);
        // 高度&深度-3 增加开关控制
        float factor = 0;
        if (_OpenHeight == 1 && _OpenDepth == 1)
        {
            // factor = heightDensity * depthDensity * (1 - noise);
            factor = heightDensity * _FogDepthDensity * depth * (1 - noise);
        }
        else if (_OpenHeight == 1)
        {
            // factor = (_WorldFogHeight - worldPos.y - noise * _NoiseScale) / _FogHeight;       // 高度叠加noise因子      
            factor = heightDensity * (1 - noise);
        }   
        else if (_OpenDepth == 1)
        {
            // factor = max(depth * _FogDepthScale, factor);                                            // 深度因子 
            // factor = depthDensity * (1 - noise);
            // factor = depthDensity * depth;
            factor = _FogDepthDensity * depth;
        }
        factor = saturate(factor);

        half4 fogColor = _FogColor * factor;
        half4 color = lerp(mainTex, fogColor, factor);
        return color;

        // half3 color = lerp(mainTex, fogColor, factor);
        // return half4(color, mainTex.a);
    }
    ENDHLSL

    SubShader
    {
        Tags { "LightMode" = "UniversalForward" }
        ZTest Off Cull Off ZWrite Off
        // Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
