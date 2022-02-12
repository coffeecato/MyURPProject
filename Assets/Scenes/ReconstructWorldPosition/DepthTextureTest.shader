// https://blog.csdn.net/coffeecato
// 2022.0212
// 显示深度纹理
Shader "coffeecat/depth/DepthTextureTest"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float4 clipPos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.clipPos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = v.uv;
        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        // NDC深度值非线性深度
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // 观察空间线性深度
        float linear01EyeDepth = Linear01Depth(depth, _ZBufferParams);
        return half4(linear01EyeDepth, linear01EyeDepth, linear01EyeDepth, 1.0);
    }

    ENDHLSL

    SubShader
    {
        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}
            ZTest Off Cull Off ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
    FallBack "Legacy Shaders/Diffuse"
}
