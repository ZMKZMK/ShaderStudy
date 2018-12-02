Shader "Hidden/FragmentTest01"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			SetTexture[_MainTex]
			{
				
				
			}
		}
	}
}
