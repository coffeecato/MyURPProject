Shader "coffeecat/VolumetricFog/VolumetricFog"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);

    CBUFFER_START(UnityPerMaterial)
        float4 _Color;
    CBUFFER_END

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
        float3 worldPos : TEXCOORD2;
    };

    float cloudRayMarching(float3 startPoint, float3 direction)
    {
        float3 testPoint = startPoint;
        float sum = 0.0;
        direction *= 0.5;                   // 每次步进间隔
        for (int i = 0; i < 256; i++)       // 步进总长度
        {
            testPoint += direction;
            if (testPoint.x < 10.0 && testPoint.x > -10.0 
            &&  testPoint.z < 10.0 && testPoint.z > -10.0
            &&  testPoint.y < 10.0 && testPoint.y > -10.0)
            sum += 0.01;
        }
        return sum;
    }

    v2f vert(appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);
        o.uv = v.uv;
        float rawDepth = 1;
        #if defined(UNITY_REVERSED_Z)
            rawDepth = 1 - rawDepth;
        #endif
        float3 worldPos = ComputeWorldSpacePosition(v.uv, rawDepth, UNITY_MATRIX_I_VP);
        o.rayDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
        o.worldPos = worldPos;

        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        float depth01 = Linear01Depth(depth, _ZBufferParams);
        //float3 worldPos = _WorldSpaceCameraPos + depth01 * i.rayDir;
        //return half4(worldPos, 1.0);
        float cloud = cloudRayMarching(_WorldSpaceCameraPos.xyz, i.rayDir);
        half4 col = _Color * cloud;
        return col;
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
