Shader "Unlit/RadialWaves"
{
    Properties
    {
        _ColorA("ColorA", Color) = (1,1,1,1)
        _ColorB("ColorB", Color) = (1,1,1,1)
        _Repeat("Repeat pattern", Int) = 5
        _ColorStart("Color Start", Float) = 0
        _ColorEnd("Color End", Float) = 1
        _TimeStep("Time step", Range(0, 0.5)) = 0.1
        _WaveAmp("Wave Amplitude", Range(0,5)) = 0.1
    }
        SubShader
    {
        Tags {
            "RenderType" = "Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define TAU 6.28318530718
            #include "UnityCG.cginc"
            float4 _ColorA;
            float4 _ColorB;
            float _ColorStart;
            float _ColorEnd;
            float _WaveAmp;
            float _TimeStep;
            int _Repeat;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normals : NORMAL;
            };

            struct Interpolators
            {
                // float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            float GetWave(float2 uv) {
                float2 uvsCentered = uv * 2 - 1;
                float radialDistance = length(uvsCentered);

                float wave = cos((radialDistance - _Time.y * _TimeStep) * TAU * _Repeat) * 0.5 + 0.5;
                wave *= 1 - radialDistance;
                return wave;
            }

            Interpolators vert(MeshData v)
            {
                Interpolators o;

                float waveY = cos((v.uv0.y - _Time.y * 0.1) * TAU * _Repeat);
                float waveX = cos((v.uv0.x - _Time.y * 0.1) * TAU * _Repeat);

                v.vertex.y = GetWave(v.uv0) * _WaveAmp;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normals);
                o.uv = v.uv0;

                return o;
            }

            float4 frag(Interpolators i) : SV_Target{
                return lerp(_ColorA, _ColorB, GetWave(i.uv));
            }

            ENDCG
        }
    }
}
