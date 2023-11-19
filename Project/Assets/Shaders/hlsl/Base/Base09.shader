Shader "HLSL/Base09"
{
	Properties
	{   	 
		_TintColor("Tint Color", color) = (1,1,1,1)
		_Intensity("Intensity", Range(0,1)) = 0.5
		_MainTex("RGB 01", 2D) = "white" {}
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

			half4 _TintColor;
			float _Intensity;
			
			float4 _MainTex_ST;
			Texture2D _MainTex;
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
				float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
				color.rgb *= _TintColor * _Intensity;
				return color;
			}
			ENDHLSL
		}
	}
}
