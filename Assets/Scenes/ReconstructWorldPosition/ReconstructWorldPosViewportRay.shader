Shader "coffeecat/depth/ReconstructWorldPosViewportRay"
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
        float4 pos : SV_POSITION;       // SV_POSITION和SV_Target不要省略
        float2 uv : TEXCOORD0;
        float3 rayDir : TEXCOORD1;
    };

    v2f vert(appdata v)
    {
        v2f o;
        // 重建世界坐标
        o.pos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = v.uv;
        float rawDepth = 1;
        #if defined(UNITY_REVERSED_Z)
            rawDepth = 1 - rawDepth;
        #endif
        float3 worldPos = ComputeWorldSpacePosition(v.uv, rawDepth, UNITY_MATRIX_I_VP);
        o.rayDir = worldPos - _WorldSpaceCameraPos.xyz;

        // 类似的方法重建视图坐标
        // o.pos = TransformObjectToHClip(v.vertex.xyz);
        // o.uv = v.uv;
        // float4 clipPos = float4(v.uv * 2 - 1, 1, 1);
        // float4 viewRay = mul(unity_CameraInvProjection, clipPos);       // 注意这里是投影矩阵的逆矩阵
        // o.rayDir = viewRay.xyz / viewRay.w;

        return o;
    }

    float4 frag(v2f i) : SV_Target
    {
        float depthTextureValue = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        // #if defined(UNITY_REVERSED_Z)
        //     depthTextureValue = 1 - depthTextureValue;
        // #endif
        // float ndc = float4(i.uy.x * 2 - 1, i.uv.y * 2 - 1, depthTextureValue, 1);
        float linear01Depth = Linear01Depth(depthTextureValue, _ZBufferParams);
        // worldPos = camePos + depth * 射线方向
        float3 worldPos = _WorldSpaceCameraPos + linear01Depth * i.rayDir;
        // 为什么y反转了？？
        #if UNITY_UV_STARTS_AT_TOP
            worldPos.y = 1 - worldPos.y;
        #endif
        return float4(worldPos, 1.0);
    }
    ENDHLSL

    SubShader
    {
        Pass
        {
            ZTest Off Cull Off ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
