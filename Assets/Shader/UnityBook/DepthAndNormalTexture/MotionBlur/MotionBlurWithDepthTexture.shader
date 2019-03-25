// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/MotionBlurWithDepthTexture"
{
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0
	}
		SubShader{
			CGINCLUDE

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _CameraDepthTexture;
			float4x4 _CurrentViewProjectionInverseMatrix;
			float4x4 _PreviousViewProjectionMatrix;
			half _BlurSize;

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				half2 uv_depth : TEXCOORD1;
			};

			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = v.texcoord;
				o.uv_depth = v.texcoord;

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv_depth.y = 1 - o.uv_depth.y;
				#endif

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				// Get the depth buffer value at this pixel.
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
				// depth[0,1] = 0.5*depthInNDC + 0.5 =>> depthNDC[-1,1] = (depth - 0.5)/0.5 = depth*2 + 1
				// i.uv.xy纹理坐标充当为视口坐标[0,1] =>> i.uv.xy*2 - 1 = NDC坐标下的xy[-1,1]
				float4 currentNDCPos = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth  * 2 - 1, 1);
				//float4 currentNDCPos = float4((i.pos.x * _MainTex_TexelSize.x) * 2 - 1, (i.pos.y * _MainTex_TexelSize.y) * 2 - 1, d * 2 - 1, 1);
				// Transform by the view-projection inverse.获得当前当前像素的世界坐标
				float4 tempWorldPos = mul(_CurrentViewProjectionInverseMatrix, currentNDCPos);
				// 证明过程：http://feepingcreature.github.io/math.html
				float4 worldPos = tempWorldPos / tempWorldPos.w;

				// Use the world position, and transform by the previous view-projection matrix.  
				float4 previousNDCPos = mul(_PreviousViewProjectionMatrix, worldPos);
				// Convert to nonhomogeneous points [-1,1] by dividing by w.
				// 上一帧NDC坐标
				previousNDCPos /= previousNDCPos.w;

				// 计算速度，时间使用2而非detalTime，只是方便_BlurSize取值而已
				float2 velocity = (currentNDCPos.xy - previousNDCPos.xy) / 2.0f;

				float2 uv = i.uv;
				float4 texel = tex2D(_MainTex, uv);
				uv += velocity * _BlurSize;
				//通过片元的速度正方向，找到前两帧中，有可能会落在当前片元的两个texel，并与当前片元的texel进行平均混合【_BlurSize用于控制采样距离】
				for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
					float4 currentColor = tex2D(_MainTex, uv);
					texel += currentColor;
				}
				texel /= 3;

				return fixed4(texel.xyzw);
			}

			ENDCG

			Pass {
				ZTest Always Cull Off ZWrite Off

				CGPROGRAM

				#pragma vertex vert  
				#pragma fragment frag  

				ENDCG
			}
		}
	FallBack Off
}
