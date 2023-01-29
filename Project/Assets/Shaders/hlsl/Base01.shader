Shader "HLSL/Base01"
{
    Properties
    {
        _TintColor ("Color", color) = (1,1,1,1)
        _Intensity ("Range Sample", Range(0,1)) = 0.5
        _MainTex ("RGB(A)", 2D) = "white" {}
    }
    SubShader
    {
        // 태그 선언 안하면 기본으로 설정
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }

        Pass
        {
            Name "Universal Forward"
            Tags { "LightMode" = "UniversalForward"}

            HLSLPROGRAM

            // #pragma 
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            // #include 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // vertex buffer에서 읽어올 정보를 선언합니다.
            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // 버텍스 셰이더에서 픽셀 셰이더로 전달할 정보를 선언합니다.
            // 보간기 : Vertex Shader에서 픽셀 Shader로 이동할 때 
            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv1 : TEXCOORD0;
            };

            float _Intensity;
            half4 _TintColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // 버텍스 셰이더
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv1 = v.uv.xy;
                return o;
            }

            // 픽셀 셰이더
            half4 frag(VertexOutput i) : SV_Target
            {
                float2 uv = i.uv1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 color = tex2D(_MainTex, uv) * _TintColor * _Intensity;

                return color;
            }
            ENDHLSL
        }
    }
}
