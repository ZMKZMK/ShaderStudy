using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class EdgeDetectWithNormalAndDepth : PostEffectsBase
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

        [SerializeField,Range(0.0f, 1.0f)]
        protected float edgesOnly = 0.0f;
        [SerializeField, Header("边缘颜色")]
        protected Color edgeColor = Color.black;
        [SerializeField, Header("背景颜色")]
        protected Color backgroundColor = Color.white;
        [SerializeField,Header("深度法线纹理坐标Reborts采样距离")]
        protected float sampleDistance = 1.0f;
        [SerializeField]
        protected float sensitivityDepth = 1.0f;
        [SerializeField]
        protected float sensitivityNormals = 1.0f;

        protected virtual void OnEnable()
        {
            GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
        }

        //OnRenderImage()会在所有不透明和透明的Pass执行完后再进行调用
        //使用[ImageEffectOpaque]属性，可以在不透明的Pass(queue<=2500)执行后立刻调用
        [ImageEffectOpaque]
        protected virtual void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                material.SetFloat("_EdgeOnly", edgesOnly);
                material.SetColor("_EdgeColor", edgeColor);
                material.SetColor("_BackgroundColor", backgroundColor);
                material.SetFloat("_SampleDistance", sampleDistance);
                material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

                Graphics.Blit(src, dest, material);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}
