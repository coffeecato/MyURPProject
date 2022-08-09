Shader "coffeecat/VolumetricFog/SampleUVW"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _VolumeTex ("3D tex", 3D) = "white" {}
        _offset ("offset", Vector) = (0,0,0,0)
        _uvwScale ("uvwScale", Vector) = (1,1,1,1)
        _mipLevel ("_mipLevel", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off 
        //ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE3D(_VolumeTex); SAMPLER(sampler_VolumeTex);
            float4 _offset, _uvwScale;
            float _mipLevel;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 posW : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.posW = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 tex3DUvw = float3(i.posW.xyz + _offset.xyz) * _uvwScale.xyz;
                float4 colorSample = _VolumeTex.SampleLevel(sampler_VolumeTex, tex3DUvw, 1);

                //return float4(normalize(tex3DUvw), 1.0);
                return colorSample;
            }
            ENDHLSL
        }
    }
}
