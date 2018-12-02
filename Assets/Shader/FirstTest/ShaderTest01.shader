Shader "Hidden/ShaderTest01"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		
		_Test01Color("Test01Color", Color) = (1,0,0,1)

	}
	SubShader
	{
		Pass
		{
			Color [_Test01Color]

			Material
			{
				//Diffuse (1,1,1,1)//漫反射
				//Ambient ()//环境光
				//Specular [_Test01Color]//镜面反射
				Emission [_Test01Color]

			}

			Lighting On//灯光打开
			SeparateSpecular On //镜面高光反射打开
		}
	}
}
