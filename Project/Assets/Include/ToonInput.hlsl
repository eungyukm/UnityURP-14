#ifndef TOON_INPUT_INCLUDED
#define TOON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_BumpMap);
TEXTURE2D(_EmissionMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half3 _Shadow1Color;
half _Shadow1Step;
half _Shadow1Feather;
half _Shadow2Step;
half _Shadow2Feather;
half3 _Shadow2Color;
half _DiffuseRampV;
half _InShadowMapStrength;
half _SSAOStrength;
half _ReceiveHairShadowOffset;

half4 _EmissionColor;
half _OcclusionStrength;
half _Cutoff;
half _BumpScale;

half _Smoothness;
half _Metallic;
half4 _SpecColor;
half _SpecularStep;
half _SpecularFeather;
half _SpecularShift;
half _SpecularShiftIntensity;
float4 _SpecularShiftMap_ST;

half _OutlineWidth;
half4 _OutlineColor;

half2 _LdotFL;
float4 _SDFShadowMap_TexelSize;

half3 _MatCapColor;
half _MatCapUVScale;
CBUFFER_END

TEXTURE2D(_ClipMask);
TEXTURE2D(_InShadowMap);
TEXTURE2D(_OcclusionMap);   
TEXTURE2D(_MetallicGlossMap);  
TEXTURE2D(_SpecGlossMap); 

#ifdef _SDFSHADOWMAP
TEXTURE2D(_SDFShadowMap);   SAMPLER(sampler_SDFShadowMap);
#endif

#ifdef _DIFFUSERAMPMAP
TEXTURE2D( _DiffuseRampMap);  SAMPLER(sampler_LinearClamp);
#endif

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_BaseMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_BaseMap, uv)
#endif

struct SurfaceDataToon
{
    half3 albedo;
    half3 specular;
    half metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
};

struct InputDataToon
{
    float3  positionWS;
    half3   normalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
    float2  normalizedScreenSpaceUV;
    half4   shadowMask;
    half3   tangentWS;
    half3   bitangentWS;
    float depth;
};

struct ToonData
{
    //Shadow
    #ifndef _DIFFUSERAMPMAP
    half3 shadow1;
    half shadow1Step;
    half shadow1Feather;
    half3 shadow2;
    half shadow2Step;
    half shadow2Feather;
    #endif
};

half SampleClipMask(float2 uv)
{
    #ifdef _ALPHATEST_ON
    #ifdef _INVERSECLIPMASK
    return 1.0h - SAMPLE_TEXTURE2D(_ClipMask,sampler_BaseMap,uv).r;
    #else
    return SAMPLE_TEXTURE2D(_ClipMask,sampler_BaseMap,uv).r;
    #endif
    #else
    return 1.0;
    #endif
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    half4 color = SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
    color.a *= SampleClipMask(uv);
    return color;
}

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    half alpha = color.a * albedoAlpha;
    #if defined(_ALPHATEST_ON)
    clip(alpha - cutoff);
    #endif

    return alpha;
}


half4 SampleMetallicSpecGloss(float2 uv, half smoothness)
{
    half4 specGloss = SAMPLE_METALLICSPECULAR(uv);
    #if _SPECULAR_SETUP
    specGloss.rgb *= _SpecColor.rgb;
    #else
    specGloss.rgb *= _Metallic.rrr;
    #endif
    specGloss.a *= smoothness;
    return specGloss;
}

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_BaseMap), half scale = 1.0h)
{
    #ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_BaseMap, uv);
    #if BUMP_SCALE_NOT_SUPPORTED
    return UnpackNormal(n);
    #else
    return UnpackNormalScale(n, scale);
    #endif
    #else
    return half3(0.0h, 0.0h, 1.0h);
    #endif
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
    // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
    #if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_BaseMap, uv).g;
    #else
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_BaseMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
    #endif
    #else
    return 1.0;
    #endif
}

half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_BaseMap))
{
    #ifndef _EMISSION
    return 0;
    #else
    return SAMPLE_TEXTURE2D(emissionMap, sampler_BaseMap, uv).rgb * emissionColor;
    #endif
}

half SampleInShadow(float2 uv)
{
    half inShadow = (1 - SAMPLE_TEXTURE2D(_InShadowMap,sampler_BaseMap,uv).r) * _InShadowMapStrength;
    return 1 - inShadow;
}

inline void InitializeSurfaceDataToon(float2 uv,out SurfaceDataToon outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    half4 specGloss = SampleMetallicSpecGloss(uv, _Smoothness);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    #if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
    #else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    #endif
    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BaseMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_BaseMap));
}

inline void InitializeToonData(float2 uv, float2 normalizedScreenSpaceUV,float3 albedo, half occlusion, float depth, out ToonData outToonData)
{
    #ifndef _DIFFUSERAMPMAP
    outToonData.shadow1 = albedo * _Shadow1Color;
    outToonData.shadow1Step = _Shadow1Step;
    outToonData.shadow1Feather = _Shadow1Feather;
    outToonData.shadow2 = albedo * _Shadow2Color;
    outToonData.shadow2Step = _Shadow2Step;
    outToonData.shadow2Feather = _Shadow2Feather;
    #endif
}
#endif