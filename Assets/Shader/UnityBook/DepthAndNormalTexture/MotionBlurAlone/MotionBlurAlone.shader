Shader "MingShader/MotionBlurAlone"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Tags{ "Queue" = "Transparent" }
		//shader不受投影器(projectors)的影响
		Tags{ "IgnoreProjector" = "True" }
		//归为透明的着色器
		Tags{ "RenderType" = "Transparent" }

        LOD 100
		CGINCLUDE
		#include "UnityCG.cginc"
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};
		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float3 speedVector;

		v2f vert(appdata v)
		{
			v2f o;
			v.vertex = mul(unity_ObjectToWorld, v.vertex);
			v.vertex.x -= speedVector.x * 2;
			v.vertex.y -= speedVector.y * 2;
			v.vertex.z -= speedVector.z * 2;
			o.pos = mul(UNITY_MATRIX_VP, v.vertex);
			o.uv = v.uv;
			return o;
		}

		fixed4 fragForGhost(v2f i) :SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);
			return fixed4(col.xyz, 0.3f);
		}
		ENDCG

        Pass
        {
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragForGhost
            ENDCG
        }
    }
}
