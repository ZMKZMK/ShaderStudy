using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class BrightnessSaturationAndContrast : PostEffectsBase
    {
        [SerializeField] private Shader briSatConShader;
        [SerializeField] private Material briSatConMaterial;

        [SerializeField]
        public Material material
        {
            get
            {
                briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
                return briSatConMaterial;
            }
        }

        [SerializeField, Range(0.0f, 3.0f), Header("亮度")]
        private float brightness = 3.0f;

        [SerializeField, Range(0.0f, 3.0f), Header("饱和度")]
        private float saturation = 3.0f;

        [SerializeField, Range(0.0f, 3.0f), Header("对比度")]
        private float contrast = 3.0f;

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            //材质是否可用
            if (material != null)
            {
                material.SetFloat("_Brightness", brightness);
                material.SetFloat("_Saturation", saturation);
                material.SetFloat("_Contrast", contrast);

                Graphics.Blit(src, dest, material);
            }
            else
            {
                //直接将src拷贝给dest进行显示到屏幕上，不做任何处理 || 若dest=null则直接显示src
                Graphics.Blit(src, dest);
            }
        }
    }
}
