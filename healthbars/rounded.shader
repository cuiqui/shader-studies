Shader "Unlit/SDF" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
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
            float4 _MainTex_ST;
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

                // Now the center of the square is (0,0) and the edges are
                // (1,1), (-1,1), (-1,-1), (1, -1)
                o.uv = v.uv;
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {

                // Rounding and clipping. Basically, we draw an imaginary line in the
                // center of the rectangle (at y = 0.5), then we normalize y-axis to be
                // 1 at the top, 0 at 0.5, and 1 again at the bottom. Finally, we measure
                // the distance between the pixel and its closest point to the line.
                // Since we normalized the coordinates, if the distance is greater than
                // 1, then we should clip the pixels.
                float2 coords = i.uv;
                coords.x *= 8;
                float2 pointOnLineSeg = float2(clamp(coords.x, 0.5, 7.5), 0.5);
                float sdf = distance(coords, pointOnLineSeg) * 2 - 1;
                clip(-sdf);

                float healhbarMask = _Health > i.uv.x;
                float3 healthbarColor = tex2D(_MainTex, float2(_Health, i.uv.y));

                // Ways of branching the shader to start flashing below a threshold
                // An "if"
                if (_Health < 0.2) {
                    float flash = cos(_Time.y * 4) * 0.4 + 1;
                    healthbarColor *= flash;
                }
                return float4(healthbarColor * healhbarMask, 1);
            }
            ENDCG
        }
    }
}
