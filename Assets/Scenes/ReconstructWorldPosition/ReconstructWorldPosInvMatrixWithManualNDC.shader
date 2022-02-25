// https://blog.csdn.net/coffeecato
// 2022.0225
// 使用逆矩阵重建世界坐标，手动计算NDC坐标，ComputeClipSpacePosition，ComputeWorldSpacePosition的使用
Shader "coffeecat/depth/ReconstructWorldPosInvMatrixWithManualNDC"
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
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(appdata v)
    {
        v2f output;
        output.pos = TransformObjectToHClip(v.vertex.xyz);
        output.uv = v.uv;

        return output;
    }

    float4 frag(v2f i) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // 解决 OpenGL 运行后会偏色、偏移
        #if UNITY_REVERSED_Z                                // UNITY_REVERSED_Z = 1 in D3D
            // D3D depth 已经在[0, 1]范围内
        #else
            // OpenGL depth 映射到[-1, 1]范围内
            // UNITY_NEAR_CLIP_VALUE = 1.0  in D3D
            // UNITY_NEAR_CLIP_VALUE = -1.0 in OpenGL
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        #endif

        // 方法1[uv->ndc->world pos] 手动计算ndc
        float4 positionNDC = float4(i.uv.xy * 2 - 1, depth, 1);      // 这一步其实就是ComputeClipSpacePosition,算出来的就是clip pos?
        float4 positionWS = mul(UNITY_MATRIX_I_VP, positionNDC);
        positionWS /= positionWS.w;

        // 方法2 [ndc->clip pos->world pos] 使用ComputeClipSpacePosition替代positionNDC
        // float4 positionCS = ComputeClipSpacePosition(i.uv, depth);   // 这里i.uv当成ndc传入的？
        // #if UNITY_UV_STARTS_AT_TOP              // 本来不用翻转的，因为ComputeClipSpacePosition内部擅作主张翻转了一次，这里再翻转回来。
        //     positionCS.y = -positionCS.y;
        // #endif
        // float4 positionWS = mul(UNITY_MATRIX_I_VP, positionCS);
        // positionWS /= positionWS.w;

        // 方法3 使用ComputeWorldSpacePosition替代手动计算ndc，ComputeClipSpacePosition
        // float3 positionWS = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);
        // // [frag]解决 DX 运行后上下翻转（DX需要翻转uv.y; OPENGL不需要）
        // // 参见：https://docs.unity3d.com/2019.4/Documentation/Manual/SL-PlatformDifferences.html
        // #if UNITY_UV_STARTS_AT_TOP 
        //     positionWS.y = -positionWS.y;
        // #endif

        return float4(positionWS.xyz, 1);
    }

    // 重新映射depth的另一种写法
    float4 fragRemapDepth(v2f i) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // 解决 OpenGL 运行后会偏色、偏移
        // 下面的方法与上面通过UNITY_NEAR_CLIP_VALUE判断的方法本质上一样
        #if UNITY_UV_STARTS_AT_TOP  // D3D
            // DirectX 平台下，depth无需映射 depth texture[0, 1] => NDC.z[0, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth, 1);
        #else
            // OpenGL 平台下，depth需要映射 depth texture[0, 1] => NDC.z[-1, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1);
        #endif
        
        float4 worldPos = mul(UNITY_MATRIX_I_VP, ndc);
        worldPos /= worldPos.w;
        return worldPos;
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
            // #pragma fragment fragRemapDepth
            ENDHLSL
        }
    }
}
