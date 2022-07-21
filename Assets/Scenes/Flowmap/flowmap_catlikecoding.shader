Shader "coffeecat/Flowmap/flowmap_catlikecoding"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [NoScaleOffset] _FlowMap ("Flow (RG, A Noise)", 2D) = "black" {}
        _UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _Tiling("Tiling", Float) = 1
        _Speed("Speed", Float) = 1
        _FlowStrength("Flow Strength", Float) = 1
        _FlowOffset("Flow Offset", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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

            sampler2D _MainTex, _FlowMap;
            float4 _MainTex_ST;
            half4 _Color;
            float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset;

            float3 FlowUVW (float2 uv, float2 flowVector, float2 jump, float flowOffset, float tiling, float time, bool flowB)
            {
                float phaseOffset = flowB ? 0.5 : 0;
                float progress = frac(time + phaseOffset);
                float3 uvw;
                //uvw.xy = uv - flowVector * progress + phaseOffset;
                //To keep the flow the same regardless of the tiling, we have to apply it to the UV after flowing, 
                //but before adding the offset for phase B.
                
                uvw.xy = uv - flowVector * (progress + flowOffset);     //flowOffset影响每个阶段开始时uv的状态
                uvw.xy *= tiling;                                       //增加Tiling的时机：uv计算完flow之后，添加阶段offset之前
                uvw.xy += phaseOffset;

                uvw.xy += (time - progress) * jump;
                uvw.z = 1 - abs(1 - 2 * progress);
                return uvw;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 flowVector = tex2D(_FlowMap, i.uv).rg * 2 - 1;
                flowVector *= _FlowStrength;
                //flowVector = 0;
                float noise = tex2D(_FlowMap, i.uv).a;
                float time = _Time.y * _Speed + noise;
                float2 jump = float2(_UJump, _VJump);
                //jump = 0;
                float3 uvwA = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, false);
                float3 uvwB = FlowUVW(i.uv, flowVector, jump, _FlowOffset, _Tiling, time, true);

                half4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
                half4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

                half4 col = (texA + texB) * _Color;
                return col;
                //return half4(flowVector, 0, 0);
            }
            ENDCG
        }
    }
}
