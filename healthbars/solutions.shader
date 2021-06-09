Shader "Unlit/Solution" {
    Properties {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        _Health("Health", Range(0,1)) = 1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _Health;

            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            Interpolators vert (MeshData v) {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float InverseLerp(float a, float b, float v) {
                return (v - a) / (b - a);
            }

            float4 frag(Interpolators i) : SV_Target {
                // We need a mask. Healthbar will be white on one side and black on the other.
                float healthbarMask = _Health > i.uv.x;

                // To make it transparent instead of black, one way to do it is to use the "clip"
                // function, which will actually discard any values below 0. There's no partial
                // transparency though, either the fragment renders or it does not. Also, we should
                // clip as soon as we can for performance.
                // If we want to make it transparent with alpha blending, we can directly write the
                // "heatlbarMask" to the alpha channel and skip the "bgColor" part.
                // return float4(healthbarColor, healthbarMask);
                clip(healthbarMask - 0.5);

                // We have to remap our t value for the lerp in order to have two thresholds,
                // we can use inverse lerp for this. Below 0.2 we want a strong red, and above 0.8
                // a strong green, so 0.2 is our 0 and 0.8 our new 1. And we want to make sure that
                // we clamp it (with the werid named "saturate" function)
                float tHealthColor = saturate(InverseLerp(0.2, 0.8, _Health));
                float3 healthbarColor = lerp(float3(1, 0, 0), float3(0, 1, 0), tHealthColor);
                float3 bgColor = float3(0, 0, 0);

                // This lerp is actually an OR gate given that either "healthbarMask" is 0 or 1
                float3 outColor = lerp(bgColor, healthbarColor, healthbarMask);
                return float4(outColor, 0);
            }
            ENDCG
        }
    }
}
