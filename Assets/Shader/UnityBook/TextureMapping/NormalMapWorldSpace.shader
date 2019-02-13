//世界空间下的凹凸映射
Shader "MingShader/NormalMapWorldSpace" {
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
				float4 TtoW0:TEXCOORD1;				//切线坐标转世界坐标矩阵(为充分利用插值寄存器，将worldSpacePos存在w分量中)
				float4 TtoW1:TEXCOORD2;
				float4 TtoW2:TEXCOORD3;
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

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

				//conpute the matrix that transform directions from tangent space to world space
				f.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				f.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				f.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return f;
			}

			//SV_Target 每一个像素的颜色值，显示到屏幕上
			fixed4 frag(v2f f) :SV_Target{
				//get the position in world space
				float3 worldPos = float3(f.TtoW0.w,f.TtoW1.w,f.TtoW2.w);
				//conpute the light and view dir in world space
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				fixed2 packedNormal = tex2D(_BumpTex, f.uv.zw).rg;
				fixed3 tangentNormal;
				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//tangentNormal = UnpackNormal(packedNormal);
				//tangentNormal.xy *= _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				fixed3 worldNormal = normalize(float3(dot(f.TtoW0.xyz, tangentNormal), dot(f.TtoW1.xyz, tangentNormal), dot(f.TtoW2.xyz, tangentNormal)));

				//材质的反射率 （纹素值 Texel）
				fixed3 albedo = tex2D(_BodyTex,f.uv.xy).rgb * _BodyColor.rgb;

				//直射光反方向
				fixed3 worldLightDir = normalize(lightDir);//_WorldSpaceLightPos0第一个直射光的位置，位置即为光照方向(直射光)
				//-------------------------
				//漫反射颜色
				fixed3 diffuse = _LightColor0.rgb * albedo * (0.5f * (dot(worldNormal, worldLightDir)) + 0.5f);	 //_LightColor0第一个直射光的颜色
				//-------------------------
				//环境光（UNITY_LIGHTMODEL_AMBIENT在unity->window->rendering->LightingSettings中设置）
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				//-------------------------
				//视野方向(顶点->相机 方向)
				fixed3 worldViewDir = normalize(viewDir);
				//Blinn-Phong模型
				fixed3 halfDirection = normalize(worldViewDir + worldLightDir);
				//高光
				fixed3 specular = _LightColor0. rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDirection)), _Shininess);
				//-------------------------
				fixed3 finalColor = diffuse + ambient + specular;
	
				return fixed4(finalColor, 1.0);
			}	
			ENDCG
		}
	}
	FallBack "Specular"
}
