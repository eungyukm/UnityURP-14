Shader "Custom/Unlit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            // 메쉬 데이터
            struct MeshData
            {
                // 버텍스의 위치 정보
                float4 vertex : POSITION;
                // uv 정보
                float2 uv0  : TEXCOORD0;
            };
            // 보간기
            struct Interpolators
            {
                // Clip Space Position
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            half4 _Color;
            
            // 버텍스 셰이더
            Interpolators vert ( MeshData v)
            {
                Interpolators o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv0.xy;
                return o;
            }

            // 픽셀 셰이더
            half4 frag(Interpolators i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
