Shader "HLSL/Base10"
{
	Properties
	{   	 
		_FlowIntensity("FlowIntensity", Range(0,1)) = 0.5
		_MainTex("RGB 01", 2D) = "white" {}
		[NoScaleOffset]_Flowmap("Flowmap", 2D) = "white" {}
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
			Name "Universal Forward"
			Tags {"LightMode" = "UniversalForward"}
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct VertexInput
			{
				float4 vertex : POSITION;
				float2 uv 	: TEXCOORD0;
			};

			struct VertexOutput
			{
				float4 vertex 	 : SV_POSITION;
				float2 uv 	: TEXCOORD0;
			};
			float _FlowIntensity;
			
			float4 _MainTex_ST;
			Texture2D _MainTex, _Flowmap;
			SamplerState sampler_MainTex;
			
			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.x += _Time.x;
				return o;
			}

			half4 frag(VertexOutput i) : SV_Target
			{
				float4 flow = _Flowmap.Sample(sampler_MainTex, i.uv);
				i.uv += frac(_Time.x) + flow.rg * _FlowIntensity;
				
				float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
				return color;
			}
			ENDHLSL
		}
	}
}
