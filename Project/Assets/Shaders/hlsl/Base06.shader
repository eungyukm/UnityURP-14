Shader "HLSL/Base06"
{
    Properties
    {
    }
    SubShader
    {        
        Tags 
        {
            // Render Type과 Render Queue를 여기서 결정합니다.
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" 
            "Queue" = "Geometry"
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

            // 버텍스 셰이더
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv.xy;
                return o;
            }

            // 픽셀 셰이더(Pixel shader)
            half4 frag(VertexOutput i) : SV_Target
            {
                half4 color = half4(i.uv.x, i.uv.y, 0, 1);
                
                return color;
            }
            ENDHLSL
        }
    }
}
