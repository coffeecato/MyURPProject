// https://blog.csdn.net/coffeecato
// 2022.0302
// 对比几种不同的屏幕空间视口坐标(viewport coordinate)的计算方法
Shader "coffeecat/ScreenSpaceUV"
{
    HLSLINCLUDE 
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // 方法1:positionCS经由SV_POSITION定义转换为screen space pixel coordinates, 通过屏幕宽高映射到screen space viewport coordinates
    struct appdata
    {
        float4 vertex : POSITION;
    };

    struct v2f
    {
        float4 positionCS : SV_POSITION;
    };
    
    v2f vert(appdata v)
    {
        v2f o;
        o.positionCS = TransformObjectToHClip(v.vertex.xyz);
        return o;
    }

    half4 frag(v2f i) : SV_Target
    {
        //i.positionCS（语义SV_POSITION）传递到fragment后，被转换为screen space pixel coordinates[0, 0] to [width, height]
        //下面的计算就容易理解了即从screen space pixel coordinates ==> screen space viewport coordinates
        //                             [0, 0] to [width, height] ==> [0, 0] to [1, 1]
        return half4(i.positionCS.xy / _ScreenParams.xy, 0, 1);
    }
    // 方法2：调用ComputeScreenPos，在fragment中手动进行透视除法
    // struct appdata
    // {
    //     float4 vertex : POSITION;
    // };

    // struct v2f
    // {
    //     float4 positionCS : SV_POSITION;
    //     float4 positionSS : TEXCOORD0;
    // };
    
    // v2f vert(appdata v)
    // {
    //     v2f o;
    //     o.positionCS = TransformObjectToHClip(v.vertex.xyz);
    //     //ComputeScreenPos实际上返回的是经过屏幕映射的齐次裁剪空间坐标[0, 0] to [w, w]（没有做透视除法）
    //     o.positionSS = ComputeScreenPos(o.positionCS);
    //     return o;
    // }

    // half4 frag(v2f i) : SV_Target
    // {
    //     //所以这里补上透视除法
    //     return half4(i.positionSS.xy / i.positionSS.w, 0, 1);
    // }

    // 方法3：传递clip space pos到fragment，在fragment转换为screen space viewport coordinates
    //         [-w, -w] to [w, w]          ==>                   [0, 0] to [1, 1]
    // struct appdata
    // {
    //     float4 vertex : POSITION;
    // };

    // struct v2f
    // {
    //     float4 positionCS : SV_POSITION;
    //     float4 positionSS : TEXCOORD0;
    // };
    
    // v2f vert(appdata v)
    // {
    //     v2f o;
    //     o.positionCS = TransformObjectToHClip(v.vertex.xyz);
    //     o.positionSS = o.positionCS;
    //     return o;
    // }
    // half4 frag(v2f i) : SV_Target
    // {
    //     // 3.1透视除法
    //     // i.positionSS.y = -i.positionSS.y;            // Graphics API:Direct3D11.处理y轴翻转的问题
    //     // return half4(i.positionSS.xy / i.positionSS.w * 0.5 + 0.5, 0, 1);
    //     // .xy * 0.5 + 0.5有什么作用？
    //     // i.positionSS.xy * 0.5 + 0.5 由[-1, -1] to [1, 1]映射到[0, 0] to [1, 1]        (因为i.positionCS多做了一步屏幕映射，所以得到的是屏幕空间的像素坐标[0, 0] to [width, height])
    //     // 为什么i.positionSS.xy / i.positionSS.w ? 
    //     // 透视除法，由裁剪空间[-w, -w] to [w, w]转换为ndc[-1, -1] to [1, 1]

    //     // 3.2展开ComputeScreenPos，与上式逻辑上一致。点的w分量是1，方向矢量的w分量是0。这里的i.positionSS.w = 1
    //     // float2 ssPos = float2(i.positionSS.x, (i.positionSS.y * _ProjectionParams.x)) * 0.5 + i.positionSS.w * 0.5;
    //     // return half4(ssPos / i.positionSS.w, 0, 1);

    //     // 总结
    //     // TEXCOORD0语义 传递到fragment shader的数据其实已经在屏幕空间了。上面做的运算只是将[-1, -1] to [1, 1]映射到[0, 0] to [1, 1]
    //     // SV_POSITION语义 vertex shader的输出数据实际还处于裁剪空间（齐次空间、投影空间）本质上是相机平截头体空间的位置，经过GPU的运算，到达fragment时被GPU转换为屏幕空间的像素位置了。
    //     // i.positionCS.xy/ScreenParams.xy，从screen space pixel coordinate[0, 0] to [width, height]标映射到viewport coordinate[0, 0] to [1, 1]

    //     // 验证上面的猜想
    //     // 将SV_Position语义与TEXCOORD0语义在fragmnet的不同的坐标转换为viewport coordinate[0, 0] to [1, 1]
    //     // i.positionCS.xy[0, 0] to [height, height]    screen space pixel coordinate
    //     // i.positionSS.xy[-w, -w] to [w, w]            clip space coordinate
        
    //     // float2 uv1 = (float2(i.positionSS.x, (i.positionSS.y * _ProjectionParams.x)) * 0.5 + i.positionSS.w * 0.5) / i.positionSS.w;
    //     // float2 uv2 = i.positionCS.xy / _ScreenParams.xy;
    //     // return half4(abs(uv1 - uv2) * 1000, 0, 1);          // * 1000 为了将微小的差异放大
    // }

    // 方法4：VPOS语义，由于有一些历史遗留的平台差异，建议慎用。
    // https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
    // #pragma target 3.0 
    // float4 vert(float4 vertex : POSITION) : SV_POSITION
    // {
    //     return TransformObjectToHClip(vertex.xyz);
    // }

    // half4 frag(float4 positionSS : VPOS) : SV_Target
    // {
    //     return half4(positionSS.xy / _ScreenParams.xy, 0, 1);
    // }

    ENDHLSL
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
