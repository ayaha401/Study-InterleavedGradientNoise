Shader "Unlit/DIther"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Dither ("Dither", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shader/Utility/MathFunction.hlsl"
            #include "Assets/Shader/Utility/Noise.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Dither;
            CBUFFER_END

            // https://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare/
            // value : uv
            float interleavedGradientNoise(float2 value)
            {
                float f = 0.06711056 * value.x + 0.00583715 * value.y;
                return frac(52.9829189 * frac(f));
            }

            // ディザ抜きに必要な4x4の閾値
            // https://docs.unity3d.com/ja/Packages/com.unity.shadergraph@10.0/manual/Dither-Node.html
            static const float DITHER_THRESHOLDS[16] =
            {
                1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
            };
            
            // https://docs.unity3d.com/ja/Packages/com.unity.shadergraph@10.0/manual/Dither-Node.html
            // value : Ditherの強度
            // screenPosition : screenPosition
            float dither(float value, float2 screenPosition)
            {
                float2 uv = screenPosition.xy * _ScreenParams.xy;
                uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
                return value - DITHER_THRESHOLDS[index];
            }

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.positionHCS);
                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float2 viewPortPos = i.screenPos.xy / i.screenPos.w;
                float2 screenPosInPixel = viewPortPos.xy * _ScreenParams.xy;

                float ditherValue = dither(_Dither, viewPortPos);
                // ditherValue = interleavedGradientNoise(viewPortPos * 100);

                float4 col = tex2D(_MainTex, i.uv.xy);
                clip(ditherValue - (1.0 - i.uv.x));
                return col;
            }
            ENDHLSL
        }
    }
}
