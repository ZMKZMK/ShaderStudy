// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "MingShader/SimpleShader"
{
	Properties{
		_Color("Color Tint", Color) = (1.0,1.0,1.0,1.0)
	}
    SubShader
    {
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma enable_d3d11_debug_symbols
			fixed4 _Color;

			//application to vertex shader
			struct a2v{
				//POSITION：模型空间的顶点坐标
				float4 vertex : POSITION;
				//NORMAL：法线方向
				float3 normal :NORMAL;
				//TEXCOORD0：模型的第一套纹理坐标
				float4 texcoord : TEXCOORD0;
			};

			//vertex shader to fragment shader
			struct v2f{
				//SV_POSITION 顶点在裁剪空间下的坐标
				float4 pos : SV_POSITION;
				//颜色信息
				fixed3 color: COLOR0;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(  v.vertex );
				o.color = v.normal *0.5 + fixed3(0.5,0.5,0.5);
				return o; 
			}
			fixed4 frag(v2f i) : SV_Target{
				fixed3 c = i.color;
				c*=_Color.rgb;
				return fixed4(c,1.0);
			}
			ENDCG
		}
		
    }
}
