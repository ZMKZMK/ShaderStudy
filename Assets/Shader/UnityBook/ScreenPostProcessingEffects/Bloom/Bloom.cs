using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    [ExecuteInEditMode]
    public class Bloom : PostEffectsBase
    {
        [SerializeField]
        private Shader bloomShader;
        [SerializeField]
        private Material bloomMaterial = null;
        public Material material
        {
            get
            {
                bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
                return bloomMaterial;
            }
        }

        [SerializeField, Range(0, 4), Header("高斯模糊迭代次数")]
        private int iterations = 3;

        [SerializeField, Range(0.0f, 3.0f), Header("模糊范围")]
        private float blurSpread = 0.6f;

        [SerializeField, Range(1, 8), Header("缩放降采样系数")]
        private int downSample = 2;

        [SerializeField, Range(0.0f, 4.0f), Header("控制提取较亮区域的时使用的阙值")]
        private float luminanceThreshold = 0.6f;

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                material.SetFloat("_LuminanceThreshold", luminanceThreshold);

                int rtW = src.width / downSample;
                int rtH = src.height / downSample;

                //1、提取图像中较亮的区域,存入buffet0中
                RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
                buffer0.filterMode = FilterMode.Bilinear;
                Graphics.Blit(src, buffer0, material, 0);
                //2、高斯模糊迭代，模糊后较亮区域会存储在buffer0中
                for (int i = 1; i <= iterations; i++)
                {
                    material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                    RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                    // Render the vertical pass
                    Graphics.Blit(buffer0, buffer1, material, 1);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                    buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                    // Render the horizontal pass
                    Graphics.Blit(buffer0, buffer1, material, 2);

                    RenderTexture.ReleaseTemporary(buffer0);
                    buffer0 = buffer1;
                }
                //3、将较亮区域高斯模糊的纹理与原纹理进行混合
                material.SetTexture("_Bloom", buffer0);
                Graphics.Blit(src, dest, material, 3);

                RenderTexture.ReleaseTemporary(buffer0);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}

