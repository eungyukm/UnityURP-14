Shader "HLSL/Base04"
{
    Properties
    {
        _TintColor("Color", color) = (1,1,1,1)
        _MainTex ("RGB", 2D) = "white" {}
        _Intensity("Intensity", Range(0,10)) = 1
        
        // Src(Source)는 계산된 컬러를 말하고 Dst(Destination)은 이미 화면에 표시된 컬러를 말합니다.
        // Blend operation 타입이다.
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
    }
    SubShader
    {
        Blend [_SrcBlend][_DstBlend]
        Tags 
        {
            // Render Type과 Render Queue를 여기서 결정합니다.
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Transparent" 
            "Queue" = "Transparent"
        }

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
                float2 uv : TEXCOORD0;
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
            float _Intensity;

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
                half4 color = _MainTex.Sample(sampler_MainTex, i.uv);
                color.rgb *= _TintColor * _Intensity;
                color.a = color.a * _AlphaCut;
                
                return color;
            }
            ENDHLSL
        }
    }
}
