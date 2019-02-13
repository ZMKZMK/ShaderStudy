Shader "myShader/test01_03UseStruct" {
	SubShader {
	    Pass{
	        CGPROGRAM
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
            };

            //SV_POSITION 裁剪空间下的坐标
            v2f vert(a2v v){
                v2f f;
                f.position =  UnityObjectToClipPos(v.vertex);
                f.normal = v.normal;
                return f;
            }
            //SV_Target 每一个像素的颜色值，显示到屏幕上
            fixed4 frag(v2f f) :SV_Target{
                return fixed4(f.normal, 6);
            }
		    ENDCG 
		}
	}
	FallBack "VertexLit"
}
