Shader "MingShader/DissolveEffect"
{
	Properties{
			_BurnAmount("Burn Amount", Range(0.0, 1.0)) = 0.0
			_LineWidth("Burn Line Width", Range(0.0, 1.0)) = 0.1
			_MainTex("Base (RGB)", 2D) = "white" {}
			_BumpMap("Normal Map", 2D) = "bump" {}
			_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
			_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
			_BurnMap("Burn Map", 2D) = "white"{}
	}
	SubShader{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "IgnoreProjector" = "true" }

		Pass {
			Tags { "LightMode" = "ForwardBase" }

			Cull Off

			CGPROGRAM

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			fixed _BurnAmount;
			fixed _LineWidth;

			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _BurnMap;

			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//阴影纹理采样坐标
				TRANSFER_SHADOW(o);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				//噪声纹理应该只用到了R通道的数据
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;
				
				//当结果小于零，像素会被剔除。R越小，越容易被剔除，纹理越黑
				clip(burn.r - _BurnAmount);
				//切线空间下的直射光方向和法线
				float3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//smoothstep(min,max,x)：在min与max间进行平滑插值	
				//R越小，t越大，越容易消失，越会趋近于_BurnSecondColor颜色
				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
				//pow让颜色更鲜艳
				burnColor = pow(burnColor, 5);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				//t越大，越容易消失，颜色越趋近于消融的颜色----step(a,x):x>=a?1:0用step防止t没法取到0的时候出现的问题
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));
				return fixed4(finalColor, 1);
			}

			ENDCG
		}

		// Pass to render object as a shadow caster
		Pass {
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"

			//噪声
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;

			struct v2f {
				//内置宏：V2F_SHADOW_CASTER|TRANSFER_SHADOW_CASTER_NORMALOFFSET|SHADOW_CASTER_FRAGMENT等
				//用于计算阴影投射时需要的各种变量
				V2F_SHADOW_CASTER;
				float2 uvBurnMap : TEXCOORD1;
			};

			v2f vert(appdata_base v) {
				v2f o;

				//会特定的使用名称为v的结构体，并且必须包含vertex和normal
				//填充V2F_SHADOW_CASTER在背后声明的一些变量
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

				//使用噪声剔除片元
				clip(burn.r - _BurnAmount);

				//让Unity底层进行阴影投射,并把结果输出到深度图和阴影映射纹理中
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
