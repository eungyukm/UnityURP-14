Shader "HLSL/Base08"
{
	Properties
	{   	 
		_MainTex("RGB 01", 2D) = "white" {}
		_MainTex02("RGB 02", 2D) = "white" {}
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
				float2 uv2	: TEXCOORD1;
			};

			float4 _MainTex_ST;
			Texture2D _MainTex;
			SamplerState sampler_MainTex;

			float4 _MainTex02_ST;
			Texture2D _MainTex02;

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv2 = v.uv.xy * _MainTex02_ST.xy + _MainTex02_ST.zw;
				return o;
			}   				 

			half4 frag(VertexOutput i) : SV_Target
			{
				float4 tex01 = _MainTex.Sample(sampler_MainTex, i.uv);
				float4 tex02 = _MainTex02.Sample(sampler_MainTex, i.uv2);
				float4 color = lerp(tex01, tex02, i.uv.x);
				return color;
			}
			ENDHLSL
		}
	}
}
