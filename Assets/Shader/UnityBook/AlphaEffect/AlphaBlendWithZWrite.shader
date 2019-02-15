// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MingShader/AlphaBlendWithZWrite"
{
	Properties{
		_Color("Main Tint",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_AlphaScale("Alpha Scale",Range(0,1)) = 1
	}
	SubShader{
			Tags { "Queue" = "Transparent" }
			//shader不受投影器(projectors)的影响
			Tags { "IgnoreProjector" = "True" }
			//归为透明的着色器
			Tags { "RenderType" = "Transparent" }

			//把模型深度信息写入深度缓冲中，剔除模型中被自身遮挡的片元
			//但不写入
			Pass{
				ZWrite On
				ColorMask 0
			}

			Pass
			{
				Tags { "LightMode" = "ForwardBase" }
				//关闭深度写入
				ZWrite Off
				//透明度混合 源颜色混合因子和目标颜色混合因子
				//normal transparent
				Blend SrcAlpha OneMinusSrcAlpha
				//soft additive
				//Blend OneMinusDstColor One
				//2x multiply
				//Blend DstColor SrcColor
				//Darken
				//BlendOp Min
				//Blend One One
				//Lighten
				//BlendOp Max
				//Blend One One
				//Screen滤色
				//Blend OneMinusDstColor One
				//Blend One OneMinusSrcColor

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _AlphaScale;

				struct a2v {
					float4 vertex:POSITION;
					float3 normal:NORMAL;
					float4 texcoord: TEXCOORD0;
				};
				struct v2f {
					float4 pos:SV_POSITION;
					float3 worldNormal:TEXCOORD0;
					float3 worldPos: TEXCOORD1;
					float2 uv:TEXCOORD2;
				};
				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.worldNormal = mul(unity_ObjectToWorld, v.normal).xyz;
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}
				fixed4 frag(v2f i) :SV_Target{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed4 texColor = tex2D(_MainTex, i.uv);

					fixed3 albedo = texColor.rgb * _Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * (0.5f + dot(worldNormal, worldLightDir) * 0.5f);
					return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
				}
				ENDCG
			}
		}
	Fallback "Transparent/VertexLit"
}
