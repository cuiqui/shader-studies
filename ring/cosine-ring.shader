Shader "Unlit/Shader1"
{
    Properties {
        _ColorA("ColorA", Color) = (1,1,1,1)
        _ColorB("ColorB", Color) = (1,1,1,1)
        _Repeat("Repeat pattern", Int) = 5
        _ColorStart("Color Start", Float) = 0
        _ColorEnd("Color End", Float) = 1
    }
    SubShader  {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass {
            Blend One One  // Additive
            ZWrite Off
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define TAU 6.28318530718
            #include "UnityCG.cginc"
            float4 _ColorA;
            float4 _ColorB;
            float _ColorStart;
            float _ColorEnd;
            int _Repeat;

            

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normals : NORMAL;
            };

            struct Interpolators {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normals);  // matrix multiplication
                o.uv = v.uv0;
                return o;
            }

            float4 frag(Interpolators i) : SV_Target {

                float xOffset = cos(i.uv.x * TAU * 8) * 0.01;

                float t = cos((i.uv.y + xOffset - _Time.y * 0.2) * TAU * _Repeat) * 0.5 + 0.5;
                t *= 1 - i.uv.y;

                float topBottomRemover = abs(i.normal.y) < 0.999;
                float waves = t * topBottomRemover;

                float4 gradient = lerp(_ColorA, _ColorB, i.uv.y);
                return gradient * waves;
            }
            ENDCG
        }
    }
}
