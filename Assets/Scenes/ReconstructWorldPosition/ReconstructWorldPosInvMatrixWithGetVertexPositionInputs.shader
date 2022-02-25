// https://blog.csdn.net/coffeecato
// 2022.0222
// 使用逆矩阵重建世界坐标，使用GetVertexPositionInputs接口获取NDC坐标
Shader "coffeecat/depth/ReconstructWorldPosInvMatrixWithGetVertexPositionInputs"
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
        // v2f output = (v2f)0;             // 默认填充没有初始化的数据结构
        output.uv = v.uv;
        VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
        output.pos = vertexInput.positionCS;
        output.ndc = vertexInput.positionNDC;

        return output;
    }

    float4 frag(v2f i) : SV_TARGET
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // 方法1, 解决 OpenGL 运行后会偏色、偏移 
        #if UNITY_UV_STARTS_AT_TOP  // D3D
            // DirectX 平台下，depth无需映射 depth texture[0, 1] => NDC.z[0, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth, 1);
        #else
            // OpenGL 平台下，depth需要映射 depth texture[0, 1] => NDC.z[-1, 1]
            float4 ndc = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1);
        #endif
        // 方法2, 解决 OpenGL 运行后会偏色、偏移
        // #if !UNITY_REVERSED_Z       // UNITY_REVERSED_Z = 1 in D3D
        //     depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
        // #endif

        float2 positionNDC = i.ndc.xy / i.ndc.w;      
        float3 worldPos = ComputeWorldSpacePosition(positionNDC, depth, UNITY_MATRIX_I_VP);
        // [frag]解决 DX 运行后上下翻转（D3D 需要翻转uv.y；OPENGL不需要）
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
