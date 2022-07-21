Shader "coffeecat/Flowmap/flowmapEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [NoScaleOffset] _FlowMap ("FlowMap", 2D) = "black" {}
        _FlowSpeed ("Flow Speed", Float) = 0.1
        _TimeSpeed ("glowbal speed", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off Lighting Off Zwrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            sampler2D _FlowMap;
            float _FlowSpeed, _TimeSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 flowVector = tex2D(_FlowMap, i.uv).xy * 2 - 1;
                flowVector *= _FlowSpeed;

                float phase0 = frac(_Time.y * _TimeSpeed);
                float phase1 = frac(_Time.y * _TimeSpeed + 0.5);

                float3 texA = tex2D(_MainTex, i.uv - flowVector * phase0);
                float3 texB = tex2D(_MainTex, i.uv - flowVector * phase1);

                float flowLerp = abs((0.5 - phase0) / 0.5);

                half3 col = lerp(texA, texB, flowLerp);
                return half4(col, 1) * _Color;
            }
            ENDCG
        }
    }
}
