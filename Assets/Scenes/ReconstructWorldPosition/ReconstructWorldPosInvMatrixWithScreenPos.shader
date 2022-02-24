// https://blog.csdn.net/coffeecato
// 2022.0222
// 使用逆矩阵重建世界坐标，对比ComputeScreenPos 与 GetVertexPositionInputs 函数的使用
Shader "coffeecat/depth/ReconstructWorldPosInvMatrixWithScreenPos"
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
        float4 ndc : TEXCOORD1;
    };

    v2f vert(appdata v)
    {
        v2f output;
        output.uv = v.uv;
        // 方法1
        // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
        // output.pos = vertexInput.positionCS;
        // output.ndc = vertexInput.positionNDC;
        // 方法2
        // ComputeScreenPos返回值与GetVertexPositionInputs中positionNDC的计算一致
        // output.pos = TransformObjectToHClip(v.vertex.xyz);
        // output.ndc = ComputeScreenPos(output.pos);
        // 方法3
        // 手算ndc，参考GetVertexPositionInputs的实现
        output.pos = TransformObjectToHClip(v.vertex.xyz);
        float4 ndc = output.pos * 0.5f;
        output.ndc.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
        output.ndc.zw = output.pos.zw;
        
        return output;
    }

    float4 frag(v2f i) : SV_TARGET
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // 解决 DX 与 OpenGL 平台运行结果不一致（OpenGL运行会偏黄偏右）
        // 根本原因在于depth 在 DX 是[0, 1],在 OpenGL 是[-1, 1]
        #if !UNITY_REVERSED_Z                       // UNITY_REVERSED_Z = 1 in D3D
            depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        #endif
        float2 positionNDC = i.ndc.xy / i.ndc.w;     
        float3 worldPos = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP);
        // 解决y轴翻转的问题
        // 也可以用_ProjectionParams < 0 在vert中 ndc.y = 1 - ndc.y，参见：https://docs.unity3d.com/2019.4/Documentation/Manual/SL-PlatformDifferences.html
        #if UNITY_UV_STARTS_AT_TOP 
            worldPos.y = -worldPos.y;
        #endif
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
