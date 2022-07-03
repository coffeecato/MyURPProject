// https://blog.csdn.net/coffeecato
// 2022.0410
// 实现高度雾&深度雾，优化参数
Shader "coffeecat/fog/HeightFogOptimize"
{
    Properties
    {
        [HideInInspector]_MainTex ("基础纹理", 2D) = "white"{}
        _FogColor ("Fog Color", Color) = (0.5, 0.5, 0.5, 1)

        [Toggle] _OpenHeight ("开启高度雾", Float) = 1
        _HeightRampTex ("高度渐变纹理", 2D) = "white"{}
        _FogHeightBegin ("高度雾起点", Float) = -1
        _FogHeightEnd ("高度雾终点", Float) = 15
        
        [Toggle] _OpenDepth ("开启深度雾", Float) = 1
        _DepthRampTex ("深度渐变纹理", 2D) = "white"{}
        _FogDepthDistance ("深度雾距离", Float) = 10

        _FogDensity ("雾的强度", Range(0.01, 1)) = 1
        _NoiseTex ("噪声纹理", 2D) = "white"{}
        _WorldPosScale ("noise缩放系数", Range(0, 0.1)) = 0.05
        _NoiseSpX ("噪声流动速度X：", Range(-1, 1)) = 0
        _NoiseSpY ("噪声流动速度Y：", Range(-1, 1)) = 0
        _NoiseScale ("NoiseScale", Range(0.01, 10)) = 1
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
    TEXTURE2D(_HeightRampTex); SAMPLER(sampler_HeightRampTex);
    TEXTURE2D(_DepthRampTex); SAMPLER(sampler_DepthRampTex);
    TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    float _FogHeight, _WorldFogHeight, _WorldPosScale, _NoiseSpX, _NoiseSpY, _NoiseScale, _FogDepthScale, _OpenHeight, _OpenDepth;
    float _FogDensity, _FogHeightBegin, _FogHeightEnd, _FogDepthDistance;
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
        // 计算深度
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        #if UNITY_REVERSED_Z != 1
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        #endif
        depth = Linear01Depth(depth, _ZBufferParams);
        float3 worldPos = _WorldSpaceCameraPos.xyz + depth * i.viewRayWorld;

        // 噪声模拟流动
        float2 noiseUV = worldPos.xz * _WorldPosScale + _Time.y * half2(_NoiseSpX, _NoiseSpY);
        float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
        noise *= _NoiseScale;

        // 计算高度雾，深度雾
        float factor = 1;
        half4 fogColor = _FogColor;
        half4 heightColor = 1;
        half4 depthColor = 1;
        if (_OpenHeight == 1 && _OpenDepth == 1)
        {
            float depthFactor = min(depth * _FogDepthDistance * (1 - noise), factor);
            depthColor = SAMPLE_TEXTURE2D(_DepthRampTex, sampler_DepthRampTex, noiseUV);

            float heightFactor = (_FogHeightEnd - worldPos.y - noise) / (_FogHeightEnd - _FogHeightBegin);
            heightColor = SAMPLE_TEXTURE2D(_HeightRampTex, sampler_HeightRampTex, noiseUV);

            fogColor *= depthColor * saturate(depthFactor) * heightColor * (1 - saturate(heightFactor));
            factor = saturate(depthFactor) * (1 - saturate(heightFactor));
        }
        else if (_OpenHeight == 1)
        {
            factor = (_FogHeightEnd - worldPos.y - noise) / (_FogHeightEnd - _FogHeightBegin);
            heightColor = SAMPLE_TEXTURE2D(_HeightRampTex, sampler_HeightRampTex, noiseUV);
            factor = 1 - saturate(factor);
            fogColor *= heightColor * factor;
        }  
        else if (_OpenDepth == 1)
        { 
            factor = min(depth * _FogDepthDistance * (1 - noise), factor);
            depthColor = SAMPLE_TEXTURE2D(_DepthRampTex, sampler_DepthRampTex, noiseUV);
            fogColor *= depthColor * saturate(factor);
        }
        else
        {
            factor = 1 - factor; 
        }
        factor = saturate(factor);
        // 这个算法，浓度调整不明显
        // half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        // half4 color = lerp(mainTex, fogColor, factor);
        // color.rgb = color.rgb * _FogDensity;
        // return color;
        // 优化浓度算法
        half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        fogColor = lerp(mainTex, fogColor, _FogColor.a);
        // fogColor = lerp(mainTex, _FogColor, _FogColor.a);
        half4 color = lerp(fogColor, mainTex, lerp(1, 1 - factor, _FogDensity));
        return color;
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
