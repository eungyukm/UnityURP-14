Shader "HLSL/Base12"
{
	Properties
	{   	 
		_Ambientcolor("Ambient color", color) = (0, 0, 0, 0)
		_LightWidth("Light width", Range(0, 255)) = 1
        _LightStep("Light Step", Range(0, 10)) = 1
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
				float3 light : COLOR;
			};

			struct VertexOutput
			{
				float4 vertex 	 : SV_POSITION;
				float3 normal : NORMAL;
				float3 light : COLOR;
			};

			half4 _Ambientcolor;
			float _LightWidth;
            float _LightStep;
			
			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.normal = TransformObjectToWorldNormal(v.normal);

				float3 light = _MainLightPosition.xyz;
                o.light = saturate(dot(o.normal, light)) * _MainLightColor.rgb;
				return o;
			}

			half4 frag(VertexOutput i) : SV_Target
			{
				half4 color = half4(0.5,0.5,0.5,1);
				
                float3 light = _MainLightPosition.xyz;
                float3 lightcolor = _MainLightColor.rgb;

                float3 NdotL = saturate((dot(i.normal, light)));
                
                float3 toonlight = ceil((NdotL) * _LightWidth) / _LightStep * lightcolor;

                float3 combine = NdotL > 0 ? toonlight : _Ambientcolor;
                
                color.rgb *= combine;
				return color;
			}
			ENDHLSL
		}
	}
}
