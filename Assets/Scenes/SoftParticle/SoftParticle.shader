// https://blog.csdn.net/coffeecato
// 2022.0211
// 软粒子
Shader "coffeecat/depth/SoftParticle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _InvFade ("Soft Particle Factor", Range(0.01, 3.0)) = 1.0
    }
 
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // 下面的include就很奇怪，为了实现UnityObjectToViewPos，层层套娃，本来只需include .../Core.hlsl就可，额外引入了很多。
    // 庆幸终于在2022.0211干掉了下面的引用。
    // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        half4 color : COLOR;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        half4 color : COLOR;
        float4 pos : SV_POSITION;
        float4 projPos : TEXCOORD1;
    };

    TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
    TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;    
        float _InvFade;
    CBUFFER_END

    // #define COMPUTE_EYEDEPTH(o) o = -mul( UNITY_MATRIX_MV, v.vertex ).z     // from UnityCG.cginc
    // 上述方法会触发Waring: Use of UNITY_MATRIX_MV is detected. To transform a vertex into view space, consider using UnityObjectToViewPos for better performance.
    // 2022.0208 Unity 建议使用UnityObjectToViewPos，然而URP并没有这个方法，需要自己从UnityCG.cginc抄一份过来。 
    // 下面的计算方式效率更好。上面的计算会执行更多的乘法和加法操作。（主要是UNITY_MATRIX_MV带来的，参考https://blog.csdn.net/u012871784/article/details/80885599）
    // #define COMPUTE_EYEDEPTH(o) o = -UnityObjectToViewPos(v.vertex.xyz).z
    // inline float3 UnityObjectToViewPos( in float3 pos )
    // {
    //     return mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(pos, 1.0))).xyz;
    // }
    // 2022.0211 URP SpaceTransforms.hlsl文件中定义了TransformObjectToWorld, TransformWorldToView,两个方法连起来就可以从Object->View, 用来取代UnityObjectToViewPos
    
    v2f vert (appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.vertex.xyz);    // 顶点在裁剪空间的坐标
        o.projPos = ComputeScreenPos(o.pos);             // 顶点在屏幕空间的坐标
        // 方法1
        // COMPUTE_EYEDEPTH(o.projPos.z);               // 顶点到相机的距离
        // 方法2
        // o.projPos.z = -UnityObjectToViewPos(v.vertex.xyz).z;
        // 方法3
        float3 worldPos = TransformObjectToWorld(v.vertex.xyz); // 顶点在世界空间的坐标
        float3 viewPos = TransformWorldToView(worldPos);    // 顶点在观察空间的坐标
        o.projPos.z = -viewPos.z;

        o.color = v.color;
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        return o;
    }

    half4 frag (v2f i) : SV_Target
    {
        // 顶点的线性深度（观察空间），ComputeScreenPos得到的坐标没有进行齐次除法，需要手动/w
        float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.projPos.xy / i.projPos.w), _ZBufferParams);
        // 顶点到相机的距离
        float partZ = i.projPos.z;
        // 上述两个距离越接近说明与穿插的位置越接近
        float fade = saturate(_InvFade * (sceneZ - partZ));
        i.color.a *= fade;
        half4 col = i.color * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
        col.rgb *= col.a;
        return col;
    }

    ENDHLSL

    SubShader
    {
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent"}
        Blend One OneMinusSrcColor
        ColorMask RGB
        ZWrite Off

        Pass
        {
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
