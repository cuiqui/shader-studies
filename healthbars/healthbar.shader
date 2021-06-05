Shader "Unlit/HealthBar"
{
    Properties
    {
        _ColorA("ColorA", Color) = (1,1,1,1)
        _ColorB("ColorB", Color) = (0,0,0,1)
        _Health("Health", Range(0,1)) = 1
        _MinThreshold("Min color threshold", Float) = 0.2
        _MaxThreshold("Max color threshold", Float) = 0.8
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            float4 _ColorA;
            float4 _ColorB;
            float _Health;
            float _MaxThreshold;
            float _MinThreshold;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(Interpolators i) : SV_Target {
                // Assignment 1 (a,b,c)
                // We multiply by 0 for all values bigger than _Health, so we
                // color it black.
                float t = _Health;
                if (_Health > _MaxThreshold) {
                    t = 1;
                } else if (_Health < _MinThreshold) {
                    t = 0;
                }
                float4 color = lerp(_ColorA, _ColorB, t) * (_Health > i.uv.x);
                return color;
            }
            ENDCG
        }
    }
}
