//커스텀라이트
void CustomLight_File_float(out float3 Direction, out float3 Color)
{
    #ifdef SHADERGRAPH_PREVIEW
        Direction = float3(1, 1, 1);
        Color = float3(1, 1, 1);
    #else
        Light light = GetMainLight();
        Direction = light.direction;
        Color = light.color;
    #endif
}


//커스텀라이트 셰도우
void CustomLight_Shadow_float(float3 worldPos, out float ShadowAtten)
{
    #ifdef SHADERGRAPH_PREVIEW
        ShadowAtten = 1.0f;
    #else
        //shadow Coord 만들기
        #if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
            half4 clipPos = TransformWorldToHClip(worldPos);
            half4 shadowCoord = ComputeScreenPos(clipPos);
        #else
            half4 shadowCoord = TransformWorldToShadowCoord(worldPos);
        #endif
        
        Light light = GetMainLight();
        //메인라이트가 없거나 받는 셰도우 오프 옵션이 되어 있을때는 그림자를 없앤다
        #if !defined(_MAIN_LIGHT_SHADOWS) || defined(_RECEIVE_SHADOWS_OFF)
            ShadowAtten = 1.0f;
        #endif

        //ShadowAtten 받아와서 만들기
        #if SHADOWS_SCREEN
            ShadowAtten = SampleScreenSpaceShadowmap(shadowCoord);
        #else
            ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
            half shadowStrength = GetMainLightShadowStrength();
            ShadowAtten = SampleShadowmap(shadowCoord, TEXTURE2D_ARGS(_MainLightShadowmapTexture,
            sampler_MainLightShadowmapTexture),
            shadowSamplingData, shadowStrength, false);
        #endif
    #endif
}