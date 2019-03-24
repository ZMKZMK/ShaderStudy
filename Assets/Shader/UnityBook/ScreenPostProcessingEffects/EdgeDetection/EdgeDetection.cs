using System.Collections;
using System.Collections.Generic;
using Ming;
using UnityEngine;

namespace Ming
{
    public class EdgeDetection : PostEffectsBase
    {
        [SerializeField]
        private Shader edgeDetectShader;
        [SerializeField]
        private Material edgeDetectMaterial = null;
        public Material material
        {
            get
            {
                edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
                return edgeDetectMaterial;
            }
        }

        [SerializeField,Range(0.0f, 1.0f), Header("边缘")]
        private float edgesOnly = 0.0f;
        [SerializeField,Header("边缘颜色")]
        private Color edgeColor = Color.black;
        [SerializeField, Header("背景颜色")]
        private Color backgroundColor = Color.white;

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                material.SetFloat("_EdgeOnly", edgesOnly);
                material.SetColor("_EdgeColor", edgeColor);
                material.SetColor("_BackgroundColor", backgroundColor);

                Graphics.Blit(src, dest, material);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}

