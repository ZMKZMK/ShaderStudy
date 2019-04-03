// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MingShader/EdgeDetectWithNormalAndDepth"
{
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
		SubShader{
			CGINCLUDE

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			float _SampleDistance;
			half4 _Sensitivity;

			sampler2D _CameraDepthNormalsTexture;

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[5]: TEXCOORD0;
			};

			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				half2 uv = v.texcoord;
				//原纹理坐标
				o.uv[0] = uv;

				//对深度法线纹理采样坐标进行平台差异化处理
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					uv.y = 1 - uv.y;
				#endif

				//使用Roberts算子时需要采样的深度法线纹理坐标,_SampleDistance为采样距离
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;//右上角
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;//左下角
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;//左上角
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;//右下角

				return o;
			}

			half CheckSame(half4 ASample, half4 BSample) {
				//并不需要完全解码normal，而是直接采用法线xy值分量(屏幕平面)，因为只需要比较两个采样值之间的差异度即可
				half2 ANormal = ASample.xy;
				float ADepth = DecodeFloatRG(ASample.zw);
				half2 BNormal = BSample.xy;
				float BDepth = DecodeFloatRG(BSample.zw);
				//_Sensitivity为法线和深度的比较的灵敏度
				half2 diffNormal = abs(ANormal - BNormal) * _Sensitivity.x;
				float diffDepth = abs(ADepth - BDepth) * _Sensitivity.y;
				//法线差异 | 深度差异  =>> 0为有边界
				int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
				//可以直接diffDepth < 0.1,但对于比较远的物体，表面细节不需要很丰富，可以直接不描边，可以为0.1*ADepth进行权衡
				int isSameDepth = diffDepth < 0.1 * ADepth;
				return isSameNormal * isSameDepth ? 1.0 : 0.0;
			}

			fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target {
				half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);//右上角
				half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);//左下角
				half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);//左上角
				half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);//右下角

				half edge = 1.0;

				edge *= CheckSame(sample1, sample2);
				edge *= CheckSame(sample3, sample4);

				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
			}

			ENDCG

			Pass {
				ZTest Always Cull Off ZWrite Off

				CGPROGRAM

				#pragma vertex vert  
				#pragma fragment fragRobertsCrossDepthAndNormal

				ENDCG
			}
		}
			FallBack Off
}
