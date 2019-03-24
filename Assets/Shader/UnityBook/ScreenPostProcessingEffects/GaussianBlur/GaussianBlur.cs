using System.Collections;
using System.Collections.Generic;
using Ming;
using UnityEngine;

namespace Ming
{
    public class GaussianBlur : PostEffectsBase
    {
        [SerializeField]
        private Shader gaussianBlurShader;
        [SerializeField]
        private Material gaussianBlurMaterial = null;

        public Material material
        {
            get
            {
                gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
                return gaussianBlurMaterial;
            }
        } 

        // Blur iterations - larger number means more blur.
        [SerializeField,Range(0, 4),Header("高斯模糊迭代次数")]
        private int iterations = 3;

        // Blur spread for each iteration - larger value means more blur
        [SerializeField,Range(0.0f, 3.0f),Header("模糊范围")]
        private float blurSpread = 0.6f;

        [SerializeField,Range(1, 8),Header("缩放降采样系数")]
        private int downSample = 2;

        /// 1st edition: just apply blur
        //	void OnRenderImage(RenderTexture src, RenderTexture dest) {
        //		if (material != null) {
        //			int rtW = src.width;
        //			int rtH = src.height;
        //			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
        //
        //			// Render the vertical pass
        //			Graphics.Blit(src, buffer, material, 0);
        //			// Render the horizontal pass
        //			Graphics.Blit(buffer, dest, material, 1);
        //
        //			RenderTexture.ReleaseTemporary(buffer);
        //		} else {
        //			Graphics.Blit(src, dest);
        //		}
        //	} 

        /// 2nd edition: scale the render texture
        //	void OnRenderImage (RenderTexture src, RenderTexture dest) {
        //		if (material != null) {
        //			int rtW = src.width/downSample;
        //			int rtH = src.height/downSample;
        //			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
        //			buffer.filterMode = FilterMode.Bilinear;
        //
        //			// Render the vertical pass
        //			Graphics.Blit(src, buffer, material, 0);
        //			// Render the horizontal pass
        //			Graphics.Blit(buffer, dest, material, 1);
        //
        //			RenderTexture.ReleaseTemporary(buffer);
        //		} else {
        //			Graphics.Blit(src, dest);
        //		}
        //	}

        /// 3rd edition: use iterations for larger blur
        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                int rtW = src.width / downSample;
                int rtH = src.height / downSample;

                RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
                buffer0.filterMode = FilterMode.Bilinear;//双线性插值

                Graphics.Blit(src, buffer0);

                for (int i = 1; i <= iterations; i++)
                {
                    material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                    RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                    // Render the vertical pass
                    Graphics.Blit(buffer0, buffer1, material, 0);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                    buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                    // Render the horizontal pass
                    Graphics.Blit(buffer0, buffer1, material, 1);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                }

                Graphics.Blit(buffer0, dest);
                RenderTexture.ReleaseTemporary(buffer0);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}