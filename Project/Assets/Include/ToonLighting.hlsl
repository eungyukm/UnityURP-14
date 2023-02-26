#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct BRDFDataToon
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
#if defined _HAIRSPECULAR || defined _HAIRSPECULARVIEWNORMAL
    half specularExponent;
#endif
};


half3 GlossyEnvironmentToon(half3 reflectVector, half perceptualRoughness, half occlusion)
{
    #if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);
    #if !defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    #else
    half3 irradiance = encodedIrradiance.rbg;
    #endif
    return irradiance * occlusion;
    #else
    return 0;
    #endif
}

half3 GlobalIlluminationToon(BRDFDataToon brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));
    half3 indirectDiffuse = bakedGI * occlusion * brdfData.diffuse;
    half3 reflection = GlossyEnvironmentToon(reflectVector, brdfData.perceptualRoughness, occlusion);
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    half3 indirectSpecular = surfaceReduction * reflection * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
    return indirectDiffuse + indirectSpecular;
}


inline void InitializeBRDFDataToon(SurfaceDataToon surfaceData, out BRDFDataToon outBRDFData)
{
    #ifdef _SPECULAR_SETUP
    half reflectivity = ReflectivitySpecular(surfaceData.specular);
    half oneMinusReflectivity = 1.0h - reflectivity;
    //outBRDFData.diffuse = surfaceData.albedo * (half3(1.0h, 1.0h, 1.0h) - surfaceData.specular); //Default PBR
    outBRDFData.diffuse = surfaceData.albedo;
    outBRDFData.specular = surfaceData.specular;
    #else
    half oneMinusReflectivity = OneMinusReflectivityMetallic(surfaceData.metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;
    //outBRDFData.diffuse = surfaceData.albedo * oneMinusReflectivity;
    outBRDFData.diffuse = surfaceData.albedo;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, surfaceData.albedo, surfaceData.metallic);
    #endif
    outBRDFData.grazingTerm = saturate(surfaceData.smoothness + reflectivity);
    outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surfaceData.smoothness);
    outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
    outBRDFData.roughness2 = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
    #if defined _HAIRSPECULAR || defined _HAIRSPECULARVIEWNORMAL
    outBRDFData.specularExponent = RoughnessToBlinnPhongSpecularExponent(outBRDFData.roughness);
    #endif
    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
}


half4 FragmentLitToon(InputDataToon inputData, SurfaceDataToon surfaceData, ToonData toonData)
{
    BRDFDataToon brdfData;
    InitializeBRDFDataToon(surfaceData, brdfData);

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
    #else
    half4 shadowMask = half4(1, 1, 1, 1);
    #endif
   
    
    Light mainLight = GetMainLight(inputData.shadowCoord,inputData.positionWS,shadowMask);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 color = GlobalIlluminationToon(brdfData, inputData.bakedGI, toonData.shadow1, inputData.normalWS, inputData.viewDirectionWS);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        if(IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            color += LightingToon(brdfData, surfaceData, inputData, toonData, light, 0);
        }
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += surfaceData.emission;
    return half4(color, surfaceData.alpha);
}

#endif