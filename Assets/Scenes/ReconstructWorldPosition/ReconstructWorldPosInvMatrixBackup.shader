// https://blog.csdn.net/coffeecato
// 2022.0212
// 使用逆矩阵重建世界坐标
Shader "coffeecat/depth/ReconstructWorldPosInvMatrixBackup"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    
    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;                              // 像素的纹理坐标
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;     
        float4 posNDC : TEXCOORD1;     
    };

    // v2f vert(appdata v)
    // {
    //     v2f o;
    //     o.pos = TransformObjectToHClip(v.vertex.xyz);       // 顶点在裁剪空间坐标
    //     o.uv = v.uv;
           // D3D 需要翻转uv.y;OpenGL不需要
    //     if (_ProjectionParams.x < 0)
    //         o.uv.y = 1 - o.uv.y;
        
    //     return o;
    // }

    // 方法2.2 在vert中计算ndc
    v2f vert(appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);       // 顶点在裁剪空间坐标
        o.uv = v.uv;

        float4 posNDC = o.pos * 0.5f;
        posNDC.xy = float2(posNDC.x, posNDC.y * _ProjectionParams.x) + posNDC.w;
        posNDC.zw = o.pos.zw;
        o.posNDC = posNDC;

        // D3D 需要翻转uv.y;OpenGL不需要
        if (_ProjectionParams.x < 0)
            o.posNDC.y = 1 - o.posNDC.y;
        
        // 【验证】 ComputeScreenPos 与上面的计算结果一致吗？
        // computeScreenPos计算的结果是什么？
        // posNDC[-1, 1]只是中间过程？最终采样depth texture 还是需要转换到[0, 1](而posScreen屏幕空间的坐标就是这里)
        // screenPos / w = NDC pos? 不对
        return o;
    }

    // 方法1 使用NDC坐标，视图投影逆矩阵重建世界坐标
    // float4 frag(v2f i) : SV_Target     
    // {
    //     // 1.NDC空间非线性深度
    //     float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
    //     //这里没有考虑反向Z 因为VP的逆矩阵已经处理好了REVERSED_Z
    //     // #if defined(UNITY_REVERSED_Z)
    //     // depthTextureValue = 1 - depthTextureValue;
    //     // #endif
    //     // 2.反向映射求出NDC坐标（有疑问，这里是NDC space还是clip space?）
    //     // [02.21] 解决不同Graphics API下显示不一致的问题（偏黄，偏移）
    //     #if UNITY_UV_STARTS_AT_TOP  // D3D
    //         // DirectX 平台下，depth无需映射 depth texture[0, 1] => NDC.z[0, 1]
    //         float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue, 1);
    //     #else
    //         // OpenGL 平台下，depth需要映射 depth texture[0, 1] => NDC.z[-1, 1]
    //         float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue * 2 - 1, 1);
    //     #endif
        
    //     // 【flip y】需要手动处理uv.y的翻转
    //     #if UNITY_UV_STARTS_AT_TOP  // D3D
    //         ndc.y = -ndc.y;
    //     #endif
    //     // 3.使用观察投影变换的逆矩阵
    //     float4 worldPos = mul(UNITY_MATRIX_I_VP, ndc);
    //     // 为啥要除以w？
    //     // 看起来比较简单，但是其中有一个/w的操作，如果按照正常思维来算，应该是先乘以w，然后进行逆变换，
    //     // 最后再把world中的w抛弃，即是最终的世界坐标，不过实际上投影变换是一个损失维度的变换，我们
    //     // 并不知道应该乘以哪个w，所以实际上上面的计算，并非按照理想的情况进行的计算，而是根据计算推导而来。
    //     // 原文链接：https://blog.csdn.net/puppet_master/article/details/77489948
    //     worldPos /= worldPos.w;
    //     return worldPos;
    // }

    // 方法1.1 使用内置的宏解决D3D和OpenGL上depth的差异
    // float4 frag(v2f i) : SV_Target     
    // {
    //     // 1.NDC空间非线性深度
    //     float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
    //     // 2.反向映射求出NDC坐标（有疑问，这里是NDC space还是clip space?）
    //     // [02.21] 解决不同Graphics API下显示不一致的问题（偏黄，偏移）
    //     // #if UNITY_UV_STARTS_AT_TOP  // D3D
    //     //     // DirectX 平台下，depth无需映射 depth texture[0, 1] => NDC.z[0, 1]
    //     //     float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue, 1);
    //     // #else
    //     //     // OpenGL 平台下，depth需要映射 depth texture[0, 1] => NDC.z[-1, 1]
    //     //     float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue * 2 - 1, 1);
    //     // #endif
    //     // depthTextureValue = UNITY_Z_0_FAR_FROM_CLIPSPACE(depthTextureValue);
    //     // UNITY_NEAR_CLIP_VALUE = 1.0 in D3D
    //     // UNITY_NEAR_CLIP_VALUE = -1.0 in OpenGL
    //     #if UNITY_REVERSED_Z    // UNITY_REVERSED_Z = 1 in D3D
    //         depthTextureValue = lerp(UNITY_NEAR_CLIP_VALUE, 1, depthTextureValue);
    //     #endif
    //     float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue, 1);
        
    //     // 【flip y】需要手动处理uv.y的翻转
    //     #if UNITY_UV_STARTS_AT_TOP  // D3D
    //         ndc.y = -ndc.y;
    //     #endif
    //     // 3.使用观察投影变换的逆矩阵
    //     float4 worldPos = mul(UNITY_MATRIX_I_VP, ndc);
    //     worldPos /= worldPos.w;
    //     return worldPos;
    // }

    // 方法2.1 使用UNITY_NEAR_CLIP_VALUE
    // float4 frag(v2f i) : SV_Target     
    // {
    //     float2 projUV = i.pos.xy / i.pos.w;
    //     // float2 projUV = i.pos.xy / _ScaledScreenParams.xy;
    //     float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, projUV);
    //     // float depthTextureValue = SampleSceneDepth(projUV);
    //     #if !UNITY_REVERSED_Z    // UNITY_REVERSED_Z = 1 in D3D
    //         depthTextureValue = lerp(UNITY_NEAR_CLIP_VALUE, 1, depthTextureValue);
    //     #endif
    //     // float3 worldPos = ComputeWorldSpacePosition(i.uv, depthTextureValue, UNITY_MATRIX_I_VP);
    //     float3 worldPos = ComputeWorldSpacePosition(projUV, depthTextureValue, UNITY_MATRIX_I_VP);
        
    //     return float4(worldPos, 1);
    // }
    
    // 方法2.2 在vert中计算ndc
    // 【问题】y轴上下翻转，在Vert中解决（翻转posNDC.y）
    // 【问题】统一在vert中计算ndc和在frag中计算ndc的区别
    float4 frag(v2f i) : SV_Target     
    {
        float2 projUV = i.posNDC.xy / i.posNDC.w;
        // float2 projUV = i.pos.xy / _ScaledScreenParams.xy;
        float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, projUV);
        // float depthTextureValue = SampleSceneDepth(projUV);
        #if !UNITY_REVERSED_Z    // UNITY_REVERSED_Z = 1 in D3D
            depthTextureValue = lerp(UNITY_NEAR_CLIP_VALUE, 1, depthTextureValue);
        #endif
        // float3 worldPos = ComputeWorldSpacePosition(i.uv, depthTextureValue, UNITY_MATRIX_I_VP);
        float3 worldPos = ComputeWorldSpacePosition(projUV, depthTextureValue, UNITY_MATRIX_I_VP);
        
        return float4(worldPos, 1);
    }

    ENDHLSL
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            ZTest Off Cull Off Zwrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
