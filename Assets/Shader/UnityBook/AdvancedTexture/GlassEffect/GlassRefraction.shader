// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "MingShader/GlassRefraction"
{
	Properties{
		_MainTex("Main Tex", 2D) = "white" {}//玻璃的材质
		_BumpMap("Normal Map", 2D) = "bump" {}//玻璃的法线纹理
		_Cubemap("Environment Cubemap", Cube) = "_Skybox" {}//环境映射纹理（模拟反射）
		_Distortion("Distortion", Range(0, 100)) = 10//模型折射时图像的扭曲程度
		_RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0//折射程度（0为反射1为折射）
	}
		SubShader{
			// We must be transparent, so other objects are drawn before this one.        
			// RenderType is used for Shader Replacement
			Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }

			// This pass grabs the screen behind the object into a texture.
			// We can access the result in the next pass as _RefractionTex
			GrabPass { "_RefractionTex" }

			Pass {
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				samplerCUBE _Cubemap;
				float _Distortion;
				fixed _RefractAmount;

				sampler2D _RefractionTex;//grabPass指定的纹理名称
				float4 _RefractionTex_TexelSize;//纹理的每个texel大小(用于对屏幕图像的采样坐标进行偏移)

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float2 texcoord: TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float4 scrPos : TEXCOORD0;
					float4 uv : TEXCOORD1;
					float4 TtoW0 : TEXCOORD2;
					float4 TtoW1 : TEXCOORD3;
					float4 TtoW2 : TEXCOORD4;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					//通过顶点的裁剪空间下的坐标 =>> 得到对应的采样的视口坐标[0,1]，但此视口坐标是没有进行齐次除法的视口坐标
					//x = clipx/2 + clipw/2; // 正常的视口坐标应该是: x = clipx/(2*clipw) + 1/2;
					//之所以不在vertexShader中除以clipw是为了能够在vertexShader到fragmentShader的插值过程得到正确的数据
					//原因是：投影空间(屏幕空间??)不是线性空间，插值不正确
					o.scrPos = ComputeGrabScreenPos(o.pos);

					o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);//对_MainTex玻璃材质纹理坐标采样 = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw(纹理的缩放和平移)
					o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);//对_BumpMap法线纹理(凹凸映射)坐标采样

					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//世界顶点坐标
					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//世界法线坐标
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//世界切线坐标
					fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;//世界副切线坐标(tangent.w决定了切线空间第三坐标轴的方向性)

					//计算每个顶点到对应的从 切线空间 =>> 世界空间 的变换矩阵（切线空间：x轴：切线；y轴：副切线；z轴：法线； 按列排得到变换矩阵）
					//矩阵最后一列用于存 世界坐标下的定点坐标 
					o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
					o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target {
					float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

					// Get the normal in tangent space
					//通过片元的纹理坐标对法线纹理进行采样 
					//若unity中设置法线纹理为NormalMap,则需要使用内置函数UnpackNormal解压缩
					//解压一般是：bumpNormal = packetNormal.xyz * 2 - 1 
					//			 bumpNormal.xy =  packetNormal.xy * 2 - 1;bumpNormal.z = sqrt(1-saturate(dot(bumpNormal.xy,bumpNormal.xy))
					fixed4 packetNormal = tex2D(_BumpMap, i.uv.zw);
					fixed3 bumpNormal = UnpackNormal(packetNormal);

					// Compute the offset in tangent space
					// 偏移量：切线空间(更好的表示顶点局部空间下的法线)的法线xy×折射扭曲程度×屏幕图像的texel大小(1/1920,1/1080)
					float2 offset = bumpNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;
					// 对屏幕图像的采样坐标进行偏移
					i.scrPos.xy = offset + i.scrPos.xy;
					// 补回之前vertexShader中的一个操作：对scrPos齐次透视除法得真正视口空间的坐标[0,1]
					// 再对屏幕纹理进行采样
					fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

					// Convert the normal to world space
					// 通过矩阵左乘，将法线从 切线空间 =>>> 世界空间
					bumpNormal = normalize(half3(dot(i.TtoW0.xyz, bumpNormal), dot(i.TtoW1.xyz, bumpNormal), dot(i.TtoW2.xyz, bumpNormal)));
					// 求出世界空间反射方向，并进行立方体纹理采样，再与顶点本身纹理进行混合得到反射后的颜色
					fixed3 reflDir = reflect(-worldViewDir, bumpNormal);
					fixed4 texColor = tex2D(_MainTex, i.uv.xy);
					fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;

					//_RefractAmount折射程度，0为反射，1为折射
					fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

					return fixed4(finalColor, 1);
				}

				ENDCG
			}
		}

		FallBack "Diffuse"
}
