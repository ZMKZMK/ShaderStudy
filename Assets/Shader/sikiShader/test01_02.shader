Shader "myShader/test01_02" {
	SubShader {
	    Pass{
	        CGPROGRAM
	        #include "UnityCG.cginc"
	        //声明顶点函数
#pragma vertex vert
            //声明片元函数
#pragma fragment frag
            //顶点坐  标 模型空间 -》 裁剪空间 
            float4 vert(float4 v : POSITION) : SV_POSITION{
                float4 pos = UnityObjectToClipPos(v);
                //等同于：float4 pos = mul(UNITY_MATRIX_MVP,v)
                
                return pos;
            }
            
            fixed4 frag() :SV_Target{
                return fixed4(1,1,1,1);
            }
		    ENDCG
		}
	}
	FallBack "Diffuse"
}
