﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MingShader/AlphaTest"
{
	Properties{
		_Color("Main Tint",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_Cutoff("Alpha Cutoff",Range(0,1)) = 0.5
	}
	SubShader{
			Tags { "Queue" = "AlphaTest" }
			//shader不受投影器(projectors)的影响
			Tags { "IgnoreProjector" = "True" }
			//归为透明的着色器
			Tags { "RenderType" = "TransparentCutout" }
			Pass
			{
				Tags { "LightMode" = "ForwardBase" }
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _Cutoff;

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

					//Alpha Test
					clip(texColor.a - _Cutoff);
					//if (texColor.a - _Cutoff < 0.0) {
					//	discard;
					//}
					fixed3 albedo = texColor.rgb * _Color.rgb;
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					fixed3 diffuse = _LightColor0.rgb * albedo * (0.5f + dot(worldNormal, worldLightDir) * 0.5f);
					return fixed4(ambient + diffuse, 1.0f);
				}
				ENDCG
			}
		}
	Fallback "Transparent/Cutout/VertexLit"
}
