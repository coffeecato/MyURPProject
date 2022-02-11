// https://blog.csdn.net/coffeecato
// 2022.0211
// 基于深度的扫描效果
Shader "coffeecat/depth/ScreenDepthScan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanLineColor ("Color", Color) = (1,1,1,1)
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _ScanLineColor;
    CBUFFER_END

    // 没有写在Properties列表中的属性，在BUFFER语句块中声明会导致SRP Batcher不兼容，
    // 并报警告：UnityPerMaterial var is not declared in shader property section
    float _ScanLineWidth, _ScanLightStrength, _ScanValue;

    struct appdata 
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f 
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(appdata v) 
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }

    half4 frag(v2f i) : SV_Target 
    {
        half4 screenTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);    // 采样主帖图

        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        float linear01EyeDepth = Linear01Depth(depth, _ZBufferParams);              // 观察空间下的线性深度，0 at camera, 1 at far plane.
        
        // 深度 > _ScanValue && 深度 < _ScanValue + 扫描线宽度 时显示扫描线
        if(linear01EyeDepth > _ScanValue && linear01EyeDepth < _ScanValue + _ScanLineWidth)
        {
            return screenTexture * _ScanLightStrength * _ScanLineColor;
        }
        return screenTexture;
    }
    
    ENDHLSL
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            ZTest On Cull Off ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
