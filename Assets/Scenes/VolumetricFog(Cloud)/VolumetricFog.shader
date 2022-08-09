Shader "coffeecat/VolumetricFog/VolumetricFog"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _StepCount ("step count", Float) = 500
        _RayStep ("_RayStep", Float) = 0.01

        _Noise3DTex ("Noise 3D Tex", 3D) = "white"{}
        _Noise3DScale("Noise 3D Scale", Vector) = (1,1,1,1)
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    //TEXTURE3D(_Noise3DTex);         SAMPLER(sampler_Noise3DTex);
    sampler3D _Noise3DTex;

    CBUFFER_START(UnityPerMaterial)
        float4 _Color, _Noise3DScale;
        float _StepCount, _RayStep;
        float3 _boundsMin, _boundsMax;
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

    float cloudRayMarching(float3 startPoint, float3 direction, float stepCount)
    {
        float3 testPoint = startPoint;
        float sum = 0.0;
        direction *= 0.5;                          // 每次步进间隔
        for (int i = 0; i < stepCount; i++)       // 步进总长度
        {
            testPoint += direction;
            if (testPoint.x < 10.0 && testPoint.x > -10.0 
            &&  testPoint.z < 10.0 && testPoint.z > -10.0
            &&  testPoint.y < 10.0 && testPoint.y > -10.0)
            sum += 0.01;
        }
        return sum;
    }

    float2 rayBoxDst(float3 boundsMin, float3 boundsMax,
                     float3 rayOrigin, float3 invRayDir)
    {
        //boundsMin = float3(-2.5, -2.5, -2.5);
        //boundsMax = float3(2.5, 2.5, 2.5);
        float3 t0 = (boundsMin - rayOrigin) * invRayDir;
        float3 t1 = (boundsMax - rayOrigin) * invRayDir;
        float3 tmin = min(t0, t1);
        float3 tmax = max(t0, t1);

        float dstA = max(max(tmin.x, tmin.y), tmin.z);      // 入射点
        float dstB = min(tmax.x, min(tmax.y, tmax.z));      // 出射点

        float dstToBox = max(0, dstA);
        float dstInsideBox = max(0, dstB - dstToBox);
        return float2(dstToBox, dstInsideBox);
    }

    float sampleDensity(float3 rayPos)
    {
        float3 uvw = rayPos * _Noise3DScale;
        //float4 shapeNoise = tex3D(_Noise3DTex, uvw);
        // 上面采样的数据，没有变化

        float4 shapeNoise = tex3Dlod(_Noise3DTex, float4(uvw, 0));
        return shapeNoise.r;
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
        //#region 1.3 3D纹理采样
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
        float depth01 = Linear01Depth(depth, _ZBufferParams);
        //参考
        //float3 worldPos = _WorldSpaceCameraPos + depth01 * i.rayDir;
        //float3 worldViewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
        //float depthEyeLinear = length(worldViewDir);
        //float2 rayToContainerInfo = rayBoxDst(_boundsMin, _boundsMax, _WorldSpaceCameraPos, (1 / worldViewDir));
        //简化
        float3 rayPos = i.worldPos;
        float depthEyeLinear = length(i.rayDir);
        float2 rayToContainerInfo = rayBoxDst(_boundsMin, _boundsMax, _WorldSpaceCameraPos, (1 / i.rayDir));
        float dstToBox = rayToContainerInfo.x;
        float dstInsideBox = rayToContainerInfo.y;
        //dstToBox = 10;
        //dstInsideBox = 0;
        //相机到物体的距离 - 相机到容器的距离
        float dstLimit = min(depthEyeLinear - dstToBox, dstInsideBox);

        
        float3 entryPoint = rayPos + i.rayDir * dstToBox;
        ////RayMarching
        float sumDensity = 0;
        float _dstTravelled = 0;
        for (int j = 0; j < 32; j++)
        {
            //if(_dstTravelled < 50)
            if(_dstTravelled < dstLimit)
            {
                rayPos = entryPoint + (i.rayDir * _dstTravelled);
                sumDensity += pow(sampleDensity(rayPos), 5);
                //sumDensity = pow(sampleDensity(rayPos), 5);
                if (dstLimit > 0)
                {
                    sumDensity += 0.05;
                    //if (sumDensity < 0.01) break;
                    if (sumDensity > 1) break;
                }
            }
            _dstTravelled += _RayStep;
        }

        //half4 col = half4(_dstTravelled, _dstTravelled, _dstTravelled, _dstTravelled);
        //half4 col = half4(sumDensity, sumDensity, sumDensity, 1);
        half4 col = half4(_Color.rgb, sumDensity);
        //half4 col = _Color + sumDensity;
        //#endregion

        return col;
    }


    //half4 frag(v2f i) : SV_Target
    //{
    //    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
    //    float depth01 = Linear01Depth(depth, _ZBufferParams);
    //    //float3 worldPos = _WorldSpaceCameraPos + depth01 * i.rayDir;
    //    //return half4(worldPos, 1.0);
    //    //#region 1.1 实现一个RayMarching BOX
    //    //float cloud = cloudRayMarching(_WorldSpaceCameraPos.xyz, i.rayDir, _StepCount);
    //    //half4 col = _Color * cloud;
    //    //#endregion

        
    //    //#region 1.2增加碰撞检测
    //    //参考
    //    //float3 worldPos = _WorldSpaceCameraPos + depth01 * i.rayDir;
    //    //float3 worldViewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
    //    //float depthEyeLinear = length(worldViewDir);
    //    //float2 rayToContainerInfo = rayBoxDst(_boundsMin, _boundsMax, _WorldSpaceCameraPos, (1 / worldViewDir));
    //    //简化
    //    float depthEyeLinear = length(i.rayDir);
    //    float2 rayToContainerInfo = rayBoxDst(_boundsMin, _boundsMax, _WorldSpaceCameraPos, (1 / i.rayDir));
    //    float dstToBox = rayToContainerInfo.x;
    //    float dstInsideBox = rayToContainerInfo.y;
    //    //dstToBox = 10;
    //    //dstInsideBox = 0;
    //    //相机到物体的距离 - 相机到容器的距离
    //    float dstLimit = min(depthEyeLinear - dstToBox, dstInsideBox);

    //    ////RayMarching
    //    float sumDensity = 0;
    //    float _dstTravelled = 0;
    //    for (int j = 0; j < 32; j++)
    //    {
    //        //if(_dstTravelled < 50)
    //        if(_dstTravelled < dstLimit)
    //        {
    //            if (dstLimit > 0)
    //            {
    //                sumDensity += 0.05;
    //                //if (sumDensity < 0.01) break;
    //                if (sumDensity > 1) break;
    //            }
    //        }
    //        _dstTravelled += 0.01;
    //    }

    //    half4 col = half4(_dstTravelled, _dstTravelled, _dstTravelled, _dstTravelled);
    //    //half4 col = half4(sumDensity, sumDensity, sumDensity, 1);
    //    //#endregion

    //    return col;
    //}

    ENDHLSL

    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off 
            //ZTest Always          // 会导致遮挡异常
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
