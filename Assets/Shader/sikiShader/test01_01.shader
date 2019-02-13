Shader "myShader/test01_01"{
 	Properties{
 		//属性
 		_Color("Color", Color) = (1,1,1,1)
 		_Vector("Vector",Vector) = (1,2,3.4)
 		_Int("Int",Int) = 32132
 		_Float("Float",Float) = 2.545
 		_Range("Range",Range(1,10)) = 2
 		_2D("Texture",2D) = "red"{}
 		_Cube("Cube", Cube) = "whilt"{}
 		_3D("Texture",3D) = "black" {}
 	}
 	SubShader{
 	    Pass{
 	        CGPROGRAM
 	        //float 32位
 	        float4 f4;
 	        float3 f3;
 	        float2 f2;
 	        float f1;
 	        //half 16位
 	        half4 = h4;
 	        half3 = h3;
 	        half2 = h2;
 	        half = h;
 	        //fixed 11位
 	        fixed4 fix4;
 	        fixed3 fix3;
 	        fixed2 fix2;
 	        fixed fix;
 	        
 	         	        
 	        fixed4 _Color;
 	        float4 _Vector;
 	        float _Int;
 	        float _Float;
 	        float _Range;
 	        sampler2D _2D;
 	        samplerCube _Cube;
 	        sampler3D _3D;     
 	        ENDCG
 	    }
 	}
 		//后续方案
 		Fallback "VertexLit"
 }