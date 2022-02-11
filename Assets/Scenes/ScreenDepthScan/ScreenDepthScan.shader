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
    float _ScanLineWidth, _ScanLightStrength, _ScanValue;
    CBUFFER_END

    struct appdata 
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f 
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 projPos : TEXCOORD1;
    };

    v2f vert(appdata v) 
    {
        v2f o;
        o.vertex = TransformObjectToHClip(v.vertex.xyz);
        
        o.projPos = ComputeScreenPos(o.pos);
        float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
        float3 viewPos = TransformWorldToView(worldPos);
        o.projPos.z = -viewPos.z;
        // o.projPos.z = -UnityObjectToViewPos(v.vertex.xyz).z;     // built-in function

        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }

    half4 frag(v2f i) : SV_Target 
    {
        float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        float linear01EyeDepth = Linear01Depth(depthTextureValue, _ZBufferParams);
        half4 screenTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

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
