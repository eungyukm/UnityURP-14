Shader "HLSL/Base03"
{
    Properties
    {
        _TintColor("Color", color) = (1,1,1,1)
        _MainTex ("RGB", 2D) = "white" {}
        _AlphaCut("AlphaCut", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags 
        {
            // Render Type과 Render Queue를 여기서 결정합니다.
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="TransparentCutout" 
            "Queue" = "AlphaTest"
        }
        // Alphatest Shader 작성
        // Alphatest(Cutout)이란?
        // 불투명(opaque) 오브젝트를 그린후 알파 테스트를 거쳐 픽셀값을 제거한 오브젝트가 그려지게 됩니다.
        // 모든 불투명 오브젝트를 그린 후에 알파테스트된 오브젝트를 렌더링 하는것이 효율적이기 때문에 별개의
        // 큐로 구분해서(TransparentCutout 2450)을 사용하게 됩니다.

        Pass
        {
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exculde_renderer d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            // CG : shader는 .cginc를 hlsl shader는 .hlsl을 include하게 됩니다.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // vertex buffer에서 읽어올 정보를 선언합니다.
            struct VertexInput
            {
                float4 vertex : POSITION;
                // UV1번을 사용하는 경우
                float2 uv : TEXCOORD0;
                // UV2번을 사용하는 경우
                float2 uv1 : TEXCOORD1;
            };
            
            // 버텍스 셰이더에서 픽셀 셰이더로 전달할 정보를 선언합니다.
            // 보간기 : Vertxt Shader에서 Pixcel Shader로 이동할 때
            // 보간기의 숫자는
            // 
            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // Color값은 half로 설정함
            half4 _TintColor;

            float4 _MainTex_ST;
            Texture2D _MainTex;

            SamplerState sampler_MainTex;
            float _AlphaCut;

            // 버텍스 셰이더
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                return o;
            }

            // 픽셀 셰이더(Pixel shader)
            half4 frag(VertexOutput i) : SV_Target
            {
                half4 col01 = _MainTex.Sample(sampler_MainTex, i.uv);
                // float4 col02 = _MainTex02.Sample(sampler_MainTex, i.uv);

                half4 color = col01;
                clip(color.a - _AlphaCut);
                return color;
            }
            ENDHLSL
        }
    }
}
