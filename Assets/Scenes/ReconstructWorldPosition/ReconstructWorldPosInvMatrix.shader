// https://blog.csdn.net/coffeecato
// 2022.0212
// 使用逆矩阵重建世界坐标
Shader "coffeecat/depth/ReconstructWorldPosInvMatrix"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);       // 顶点在裁剪空间坐标
        o.uv = v.uv;
        // D3D 需要翻转uv.y；OPENGL不需要
        if (_ProjectionParams.x < 0)
            o.uv.y = 1 - o.uv.y;
        
        return o;
    }

    // 方法1 使用NDC坐标，视图投影逆矩阵重建世界坐标
    float4 frag(v2f i) : SV_Target     
    {
        // 1.NDC空间非线性深度
        float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        //这里没有考虑反向Z 因为VP的逆矩阵已经处理好了REVERSED_Z
        // #if defined(UNITY_REVERSED_Z)
        // depthTextureValue = 1 - depthTextureValue;
        // #endif
        // 2.反向映射求出NDC坐标（有疑问，这里是NDC space还是clip space?）
        // [02.21]
        #if UNITY_UV_STARTS_AT_TOP  // D3D
            // DirectX 平台下，depth无需映射 depth texture[0, 1] => NDC.z[0, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue, 1);
        #else
            // OpenGL 平台下，depth需要映射 depth texture[0, 1] => NDC.z[-1, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue * 2 - 1, 1);
        #endif
        
        // 【flip y】需要手动处理uv.y的翻转
        #if UNITY_UV_STARTS_AT_TOP  // D3D
            ndc.y = -ndc.y;
        #endif
        // 3.使用观察投影变换的逆矩阵
        float4 worldPos = mul(UNITY_MATRIX_I_VP, ndc);
        // 为啥要除以w？
        // 看起来比较简单，但是其中有一个/w的操作，如果按照正常思维来算，应该是先乘以w，然后进行逆变换，
        // 最后再把world中的w抛弃，即是最终的世界坐标，不过实际上投影变换是一个损失维度的变换，我们
        // 并不知道应该乘以哪个w，所以实际上上面的计算，并非按照理想的情况进行的计算，而是根据计算推导而来。
        // 原文链接：https://blog.csdn.net/puppet_master/article/details/77489948
        worldPos /= worldPos.w;
        return worldPos;
    }
    // 方法2 使用URP封装的接口ComputeWorldSpacePosition
    // 【flip y】ComputeWorldSpacePosition的方法中会判断UNITY_UV_STARTS_AT_TOP，对positionCS.y进行翻转，所以不需要手动调用了。
    // float4 frag(v2f i) : SV_Target     
    // {
    //     float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
    //     float3 worldPos = ComputeWorldSpacePosition(i.uv, depthTextureValue, UNITY_MATRIX_I_VP);
    //     return float4(worldPos, 1);
    // }

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
