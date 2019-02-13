//切线空间下的凹凸映射
Shader "MingShader/NormalMapInTangentSpace" {
	Properties{
		//高光
		_Shininess("Shininess", Range(1.0,256)) = 2.0
		_Specular("specular", Color) = (1,1,1,1)

		//贴图
		_BodyTex("Body Texture", 2D) = "white"{}
		_BodyColor("Body Color", Color) = (1,1,1,1)

		//normal Texture
		_BumpTex("Normal Mapping", 2D) = "bump"{}
		_BumpScale("Bump Scale",Float) = 1.0
	}
	SubShader{
		Pass{
			//获取unity内置光照变量
			Tags{"LightMode" = "ForwardBase"}
			Tags{"RenderType" = "Opaque"}
			CGPROGRAM
			//光照变量定义内置文件z
			#include "Lighting.cginc"
			#include "UnityCG.cginc"
			#pragma vertex vert
			#pragma fragment frag
			struct a2v {
				float4 vertex : POSITION;   //顶点坐标
				float3 normal :NORMAL;      //法线坐标
				float4 texcoord :TEXCOORD0; //纹理坐标(x,y,0,1)
				float4 tangent : TANGENT;   //切线坐标(x,y,z,切线空间第三座标轴————副切线的方向性)
			};
			struct v2f {
				float4 position : SV_POSITION;		//裁剪坐标下的顶点
				float4 uv:TEXCOORD0;				//纹理坐标
				float3 lightDir: TEXCOORD1;			//切线空间下的光照方向
				float3 viewDir: TEXCOORD2;			//切线空间下的视角方向
			};
			fixed4 _Specular;
			float _Shininess;
			sampler2D _BodyTex;
			fixed4 _BodyColor;
			float4 _BodyTex_ST;//(缩放值，平移值)
			sampler2D _BumpTex;
			float _BumpScale;
			float4 _BumpTex_ST;//(缩放值，平移值)

			//SV_POSITION 裁剪空间下的坐标
			v2f vert(a2v v) {
				v2f f;
				f.position = UnityObjectToClipPos(v.vertex);
				//f.uv.xy = TRANSFORM_TEX(v.texcoord, _BodyTex);
				//f.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);
				f.uv.xy = v.texcoord.xy * _BodyTex_ST.xy + _BodyTex_ST.zw;
				f.uv.zw = v.texcoord.xy * _BumpTex_ST.xy + _BumpTex_ST.zw;

				//compute the binormal
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//变换矩阵(模型空间->切线空间)
				float3x3 ObjToTangentMatrix = float3x3(v.tangent.xyz, binormal, v.normal);
				//或者直接使用TANGENT_SPACE_ROTATION;获得变换矩阵rotation
				//TANGENT_SPACE_ROTATION;
				
				//light direction
				//f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				//f.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				f.lightDir = mul(ObjToTangentMatrix, mul(unity_WorldToObject, _WorldSpaceLightPos0.xyz));
				f.viewDir = mul(ObjToTangentMatrix, mul(unity_WorldToObject, _WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex.xyz)));
				return f;
			}

			//SV_Target 每一个像素的颜色值，显示到屏幕上
			fixed4 frag(v2f f) :SV_Target{
				fixed2 packedNormal = tex2D(_BumpTex, f.uv.zw).rg;
				fixed3 tangentNormal;
				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//tangentNormal = UnpackNormal(packedNormal);
				//tangentNormal.xy *= _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				//材质的反射率 （纹素值 Texel）
				fixed3 albedo = tex2D(_BodyTex,f.uv.xy).rgb * _BodyColor.rgb;

				//直射光反方向
				fixed3 tangentLightDir = normalize(f.lightDir);//_WorldSpaceLightPos0第一个直射光的位置，位置即为光照方向(直射光)
				//-------------------------
				//漫反射颜色
				fixed3 diffuse = _LightColor0.rgb * albedo * (0.5f * (dot(tangentNormal, tangentLightDir)) + 0.5f);	 //_LightColor0第一个直射光的颜色
				//-------------------------
				//环境光（UNITY_LIGHTMODEL_AMBIENT在unity->window->rendering->LightingSettings中设置）
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				//-------------------------
				//视野方向(顶点->相机 方向)
				fixed3 tangentViewDir = normalize(f.viewDir);
				//Blinn-Phong模型
				fixed3 halfDirection = normalize(tangentViewDir + tangentLightDir);
				//高光
				fixed3 specular = _LightColor0. rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDirection)), _Shininess);
				//-------------------------
				fixed3 finalColor = diffuse + ambient + specular;
	
				return fixed4(finalColor, 1.0);
			}	
			ENDCG
		}
	}
	FallBack "Specular"
}
