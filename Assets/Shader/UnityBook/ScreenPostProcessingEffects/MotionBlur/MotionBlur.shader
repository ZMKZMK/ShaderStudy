// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MingShader/MotionBlur"
{
	Properties{
		 _MainTex("Base (RGB)", 2D) = "white" {}
		 _BlurAmount("Blur Amount", Float) = 1.0
	}
		SubShader{
			CGINCLUDE

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed _BlurAmount;

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			v2f vert(appdata_img v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = v.texcoord;

				return o;
			}

			fixed4 fragRGB(v2f i) : SV_Target {
				///return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
				return fixed4(0.3, 0.3, 0.3, _BlurAmount);
			}

			fixed4 fragA(v2f i) : SV_Target {
				//return tex2D(_MainTex, i.uv);
				return fixed4(0.5,1,1,_BlurAmount);
			}

			ENDCG

			ZTest Always Cull Off ZWrite Off

			//更新渲染纹理的RGB通道
			Pass {
				//混合：源颜色的A通道 AND 1-源颜色的A通道
				//混合结果：源颜色RGBA×源颜色A + colorBuffer.RGBA×(1-源颜色A)
				Blend SrcAlpha OneMinusSrcAlpha
				//通道遮罩，只往colorBuffer中写入RGB
				ColorMask RGB

				CGPROGRAM
				#pragma vertex vert  
				#pragma fragment fragRGB  
				ENDCG
			}
			//更新渲染纹理的A通道
			Pass{
				//混合结果：源颜色A×1 + colorBuffer.RGB*0
				Blend One Zero
				ColorMask A

				CGPROGRAM
				#pragma vertex vert  
				#pragma fragment fragA
				ENDCG
			}
		 }
			 FallBack Off

}
