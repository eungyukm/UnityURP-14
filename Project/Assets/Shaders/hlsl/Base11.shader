Shader "HLSL/Base11"
{
	Properties
	{   	 
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
				float3 normal : NORMAL;
			};

			struct VertexOutput
			{
				float4 vertex 	 : SV_POSITION;
				float3 normal : NORMAL;
			};
			
			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.normal = TransformObjectToWorldNormal(v.normal);
				return o;
			}

			half4 frag(VertexOutput i) : SV_Target
			{
				float3 light = _MainLightPosition.xyz;
				float4 color = float4(1,1,1,1);
				color.rgb *= saturate(dot(i.normal, light)) * _MainLightColor.rgb;
				return color;
			}
			ENDHLSL
		}
	}
}
