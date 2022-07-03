Shader "GJ/PostEffect/Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;  //xy : MainTexUV, zw : DepthUv
                float4 interpolatedRay : TEXCOORD1;
            };

            
            //half4 _MainTex_TexelSize;
            half4 _FogColor;
                
            float _HeightFogDensity;
            float _HeightFogStart;
            float _HeightFogEnd;
            float _HeightFogRange;

            float _DepthFogDensity;
            float _DepthFogStart;
            float _DepthFogEnd;
            float4x4 _FrustumCornersRay;
            float _NoiseAmount;
            float2 _Speed;

            int _DepthFog;
            int _HeightFog;
            
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            sampler2D _NoiseTexture;
            sampler2D _RampTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv.xy = v.texcoord;
                o.uv.zw = v.texcoord;

                // #if UNITY_UV_STARTS_AT_TOP
                //     if(_MainTex_TexelSize.y < 0)
                //         o.uv.w = 1 - o.uv.w;
                // #endif

                int index = 0;
                if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5){
                    index = 0;
                }
                else if(v.texcoord.x > 0.5 && v.texcoord.y < 0.5){
                    index = 1;
                }
                else if(v.texcoord.x > 0.5 && v.texcoord.y > 0.5){
                    index = 2;
                }
                else{
                    index = 3;
                }

                // #if UNITY_UV_STARTS_AT_TOP
                //     if(_MainTex_TexelSize.y < 0)
                //         index = 3 - index;
                // #endif

                o.interpolatedRay = _FrustumCornersRay[index];

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // half depthTex = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.zw);
                // float linearDepth = LinearEyeDepth(depthTex, _ZBufferParams);

                float linearDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv.zw));
                //return linearDepth/1000;
                float3 positionWS = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
                //float3 positionVS = TransformWorldToViewDir(positionWS);
                //return frac(positionWS.x);

                float hightFogDensity = (_HeightFogEnd - positionWS.y + _HeightFogRange) / (_HeightFogEnd - _HeightFogStart);
                hightFogDensity = saturate(hightFogDensity * _HeightFogDensity);

                float3 viewWS = positionWS - _WorldSpaceCameraPos;
                float depthFogDensity = (_DepthFogEnd - viewWS.z) / (_DepthFogEnd - _DepthFogStart);
                depthFogDensity = saturate(depthFogDensity * _DepthFogDensity);


                //float linear01Depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.zw), _ZBufferParams);
                //return linear01Depth;
                float2 uvOffset = _Speed * _Time.y;
                half noise = (tex2D(_NoiseTexture, i.uv.xy + uvOffset).r-0.5) * _NoiseAmount;
                //return i.uv.x + uvOffset.x;

                // 深度雾和高度雾的开关控制
                float fogDensity = 0;
                //return _HeightFog;
                if(_DepthFog && !_HeightFog){
                    fogDensity = depthFogDensity* (1 - noise);
                }
                else if(_HeightFog && !_DepthFog){
                    fogDensity = hightFogDensity* (1 - noise);
                }
                else if(_DepthFog && _HeightFog){
                    fogDensity = saturate(hightFogDensity * depthFogDensity * (1 - noise));
                    //float fogDensity = saturate(hightFogDensity + depthFogDensity);
                    //float fogDensity = max(hightFogDensity, depthFogDensity);
                }
                else{
                    fogDensity = 0;
                }
                //return fogDensity;

                // Light light = GetMainLight();
                // half sunFogAlpha = saturate(dot(light.direction, viewWS));
                // sunFogAlpha = pow(sunFogAlpha, 1);
                // half4 fogColor = lerp(_FogColor, _SunColor, sunFogAlpha);

                
                half4 rampColor = tex2D(_RampTexture, i.uv.xx);
                half4 fogColor = _FogColor * fogDensity * rampColor;
                
                half4 finalCol = tex2D(_MainTex, i.uv.xy);
                finalCol.rgb = lerp(finalCol.rgb, fogColor, fogDensity);
                //finalCol.rgb = lerp(finalCol.rgb, _SunColor, sunFogAlpha);

                return finalCol;
            }
            ENDCG
        }
    }
}