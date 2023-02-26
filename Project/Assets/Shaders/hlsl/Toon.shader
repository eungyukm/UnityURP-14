Shader "Obliy/Toon"
{
	Properties
	{   	 
		_Cull("__cull", Float) = 2.0
		[ToggleOff]_AlphaClip("__clip", Float) = 0.0
		_SrcBlend("__src", Float) = 1.0
        _DstBlend("__dst", Float) = 0.0
		
		//Shadow
        _BaseMap("Albedo", 2D) = "white" {}
		_BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		
		//Outline
        [ToggleOff] _EnableOutline("Enable Outline",Float) = 1.0
		_OutlineColor("OutlineColor",Color)= (0.0,0.0,0.0,0.0)
        _OutlineWidth("OutlineWidth",Range(0.0,5.0)) = 0.5
	}  
	
	SubShader
	{
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"     	 
			"Queue"="Geometry"   	 
		}
		Pass
		{
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            Blend [_SrcBlend][_DstBlend]
            ZWrite On
            Cull[_Cull]
			
			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

			// Material Keywords
			#pragma shader_feature_local _SDFSHADOWMAP
			#pragma shader_feature_local_fragment _DIFFUSERAMPMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SPECULAR_SETUP

			// Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

			// GPU Instancing
			#pragma multi_compile_instancing
			
            #pragma vertex ToonForwardPassVertex
            #pragma fragment ToonForwardPassFragment

			#include "../../Include/ToonInput.hlsl"
			#include "../../Include/ToonLighting.hlsl"
			#include "../../Include/ToonForwardPass.hlsl"
			
			ENDHLSL
		}
	}
}
