Shader "coffeecat/depth/SoftParticle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _InvFade ("Soft Particle Factor", Range(0.01, 3.0)) = 1.0
    }
 
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        half4 color : COLOR;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        half4 color : COLOR;
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
    // Unity 建议使用UnityObjectToViewPos，然而URP并没有这个方法，需要自己从UnityCG.cginc抄一份过来。
    // 下面的计算方式效率更好。上面的计算会执行更多的乘法和加法操作。（主要是UNITY_MATRIX_MV带来的，参考https://blog.csdn.net/u012871784/article/details/80885599）
    #define COMPUTE_EYEDEPTH(o) o = -UnityObjectToViewPos(v.vertex.xyz).z
    inline float3 UnityObjectToViewPos( in float3 pos )
    {
        return mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(pos, 1.0))).xyz;
    }
    
    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = TransformObjectToHClip(v.vertex.xyz);
        // 顶点在屏幕空间的位置（没有进行齐次除法？
        o.projPos = ComputeScreenPos(o.vertex);
        // 顶点距离相机的距离
        // COMPUTE_EYEDEPTH(o.projPos.z);
        o.projPos.z = -UnityObjectToViewPos(v.vertex.xyz).z;
        o.color = v.color;
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        return o;
    }

    half4 frag (v2f i) : SV_Target
    {
        // ComputeScreenPos得到的坐标没有进行齐次除法，需要手动/w
        // 顶点的线性深度
        float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.projPos.xy / i.projPos.w), _ZBufferParams);
        // 顶点到相机的距离
        float partZ = i.projPos.z;
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
