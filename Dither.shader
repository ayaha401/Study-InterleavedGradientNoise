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
