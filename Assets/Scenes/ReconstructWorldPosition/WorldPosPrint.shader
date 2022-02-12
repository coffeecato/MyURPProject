// https://blog.csdn.net/coffeecato
// 2022.0212
// 打印对象在世界空间的坐标
Shader "coffeecat/depth/WorldPosPrint"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float3 worldPos : TEXCOORD0;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.vertex = TransformObjectToHClip(v.vertex.xyz);        // 顶点在裁剪空间的坐标
        o.worldPos = TransformObjectToWorld(v.vertex.xyz);      // 顶点再世界空间的坐标
        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        return half4(i.worldPos, 1.0);
    }

    ENDHLSL

    SubShader
    {
        Pass 
        {
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
    FallBack "Legacy Shaders/Diffuse"
}
