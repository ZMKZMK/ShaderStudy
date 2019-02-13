Shader "myShader/test01_04LightingModel" {
    Properties{
        _Diffuse("Diffuse Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1,128)) = 2
		_Specular("specular", Color) = (1,1,1,1)
    }
	SubShader {
	    Pass{
	        //获取unity内置光照变量
	        Tags{"LightMode" = "ForwardBase"}
	        
	        CGPROGRAM
	        //光照变量定义内置文件
	        #include "Lighting.cginc"
	        
	        
#pragma vertex vert
#pragma fragment frag
	        #include "UnityCG.cginc"
            struct a2v{
                float4 vertex : POSITION;   //顶点坐标
                float3 normal :NORMAL;      //法线坐标
                float4 texcoord :TEXCOORD0; //纹理坐标(x,y,0,1)
                float3 tangent : TANGENT;   //切线坐标
            };
            struct v2f{
                float4 position : SV_POSITION;
                float3 normal : COLOR0;
                fixed4  color : COLOR1;
            };
            fixed4 _Diffuse;
			fixed4 _Specular;
            int _Shininess;
            //SV_POSITION 裁剪空间下的坐标
            v2f vert(a2v v){
                v2f f;
                f.position =  UnityObjectToClipPos(v.vertex);
                f.normal = UnityObjectToClipPos(v.normal);
                
				//世界空间坐标下的顶点坐标
				fixed worldPosition = mul((float3x3)unity_ObjectToWorld, v.vertex);
                //法线方向
                fixed3 normalDirection = mul((float3x3)unity_ObjectToWorld, v.normal);				 //模型空间坐标转世界空间坐标，unity_ObjectToWorld为模型矩阵
                //直射光反方向
                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz - worldPosition);		 //_WorldSpaceLightPos0第一个直射光的位置，位置即为光照方向(直射光)
				//-------------------------
				//漫反射颜色
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(normalDirection, lightDirection));	 //_LightColor0第一个直射光的颜色
				//-------------------------
                //环境光（UNITY_LIGHTMODEL_AMBIENT在unity->window->rendering->LightingSettings中设置）
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				//-------------------------
                //反射方向 reflect(直射光方向 ， 法线方向)
                fixed3 reflectDirection = normalize(reflect(-lightDirection, normalDirection));
                //视野方向(顶点->相机 方向)
                fixed3 viewDirection = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex).xyz); //模型空间坐标转世界空间坐标，unity_ObjectToWorld为模型矩阵
                //高光
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDirection, viewDirection)), _Shininess);
				//-------------------------
                fixed3 finalColor = diffuse + ambient + specular;
               
                f.color = fixed4(finalColor, 1);
                return f;
            }
            
            //SV_Target 每一个像素的颜色值，显示到屏幕上
            fixed4 frag(v2f f) :SV_Target{
                return fixed4(f.color);
            }
		    ENDCG 
		}
	}
	FallBack "VertexLit"
}
