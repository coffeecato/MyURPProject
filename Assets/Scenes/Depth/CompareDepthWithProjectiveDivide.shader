// https://blog.csdn.net/coffeecato
// 2022.0228
// 对比深度采样uv的不同方法
Shader "coffeecat/depth/CompareDepthWithProjectiveDivide"
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
        // float4 pos : SV_POSITION;
        
        float2 uv : TEXCOORD0;
        float4 screenPos : TEXCOORD1;
        float depth : TEXCOORD2;
        float4 pos : TEXCOORD3;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = v.uv;
        o.screenPos = ComputeScreenPos(o.pos);
        o.depth = o.pos.z / o.pos.w;                // 裁剪空间.z / 裁剪空间.w
        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        // float d = i.screenPos.z / i.screenPos.w;
        float d = i.pos.z;
        // float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
        depth = Linear01Depth(depth, _ZBufferParams);
        
        #if UNITY_REVERSED_Z != 1                       // UNITY_REVERSED_Z = 1 in D3D
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
            d = lerp(UNITY_NEAR_CLIP_VALUE, 1, d);
            i.depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, i.depth);
        #endif
        depth = Linear01Depth(depth, _ZBufferParams);                          // 正确的
        depth = abs(d - depth);
        // depth = abs(Linear01Depth(i.depth, _ZBufferParams) - depth);        // 错误的
        
        depth *= 100;
        return half4(depth, depth, depth, 1);
    }

    // 测试SV_POSITION是否会影响传递到frag的数值
    half4 frag_testSVPOS(v2f i) : SV_TARGET
    {
        // 使用Vert到Frag自动插值的裁剪空间坐标
        float depth = i.pos.z;
        // frag透视除法
        float projDepth = i.screenPos.z / i.screenPos.w;
        // depth = projDepth;
        #if UNITY_REVERSED_Z != 1                       // UNITY_REVERSED_Z = 1 in D3D
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        #endif
        depth = depth - projDepth;
        depth = Linear01Depth(depth, _ZBufferParams);
        depth *= 1000;
        return half4(depth, depth, depth, 1);
    }

    ENDHLSL
    SubShader
    {
        Tags { "LightMode"="UniversalForward" }
        ZTest Off Cull Off ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            // #pragma fragment frag
            #pragma fragment frag_testSVPOS
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
