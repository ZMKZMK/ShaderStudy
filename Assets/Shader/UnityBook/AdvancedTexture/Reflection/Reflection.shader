// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MingShader/Reflection"
{
	Properties{
		_Color("Main Tint",Color) = (1,1,1,1)
		_ReflectColor("Reflection Color",Color) = (1,1,1,1)
		_ReflectAmount("Reflection Amount",Range(0,1)) = 1//材质反射程度
		_Cubemap("Reflection Cubemap",Cube) = "_Skybox"{}//环境映射纹理
	}
	SubShader{
					Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
					Pass {
						Tags { "LightMode" = "ForwardBase" }

						CGPROGRAM

						#pragma multi_compile_fwdbase

						#pragma vertex vert
						#pragma fragment frag

						#include "Lighting.cginc"
						#include "AutoLight.cginc"

						fixed4 _Color;
						fixed4 _ReflectColor;
						fixed _ReflectAmount;
						samplerCUBE _Cubemap;

						struct a2v {
							float4 vertex : POSITION;
							float3 normal : NORMAL;
						};

						struct v2f {
							float4 pos : SV_POSITION;
							float3 worldPos : TEXCOORD0;
							fixed3 worldNormal : TEXCOORD1;
							fixed3 worldViewDir : TEXCOORD2;
							fixed3 worldRefl : TEXCOORD3;
							SHADOW_COORDS(4)
						};

						v2f vert(a2v v) {
							v2f o;

							o.pos = UnityObjectToClipPos(v.vertex);

							o.worldNormal = UnityObjectToWorldNormal(v.normal);

							o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

							o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

							//视野方向的反向 + 法线 => 入射光方向的反向
							o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

							TRANSFER_SHADOW(o);

							return o;
						}

						fixed4 frag(v2f i) : SV_Target {
							fixed3 worldNormal = normalize(i.worldNormal);
							fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
							fixed3 worldViewDir = normalize(i.worldViewDir);
							fixed3 worldRefl = reflect(-worldViewDir, worldNormal);//逐片元 获取入射光方向

							fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

							fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

							// Use the reflect dir in world space to access the cubemap
							//入射光方向的反向 => 刚好可以进行立方体纹理采样，使用texCUBE(cubemap,reflection)
							fixed3 reflection = texCUBE(_Cubemap, worldRefl).rgb * _ReflectColor.rgb;

							UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

							// Mix the diffuse color with the reflected color
							fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount);

							return fixed4(color, 1.0);
						}
						ENDCG
					}

	}
		Fallback "Reflective/VertexLit"
}
