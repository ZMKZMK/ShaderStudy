using System.Collections;
using System.Collections.Generic;
using UnityEditor.PackageManager;
using UnityEngine;

namespace Ming
{
    public class MotionBlurWithDepthTexture : PostEffectsBase
    {
        [SerializeField]
        private Shader motionBlurShader;
        [SerializeField]
        private Material motionBlurMaterial = null;

        public Material material
        {
            get
            {
                motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
                return motionBlurMaterial;
            }
        }

        private Camera myCamera;
        public Camera camera
        {
            get
            {
                if (myCamera == null)
                {
                    myCamera = GetComponent<Camera>();
                }
                return myCamera;
            }
        }

        [SerializeField,Range(0.0f, 1.0f),Header("模糊系数(模糊采样距离)")]
        private float blurSize = 0.5f;
        [HideInInspector]
        private Matrix4x4 previousViewProjectionMatrix;

        //Inspector View
        [SerializeField,Header("相机投影矩阵")]
        private Matrix4x4 cameraProjectMatirx;
        [SerializeField,Header("相机view视图矩阵")]
        private Matrix4x4 cameraWorldToCameraMatirx;

        private void Update()
        {
            cameraProjectMatirx = camera.projectionMatrix;
            cameraWorldToCameraMatirx = camera.worldToCameraMatrix;
        }

        protected void OnEnable()
        {
            camera.depthTextureMode |= DepthTextureMode.Depth;

            //相机的投影矩阵(透视/正交) × 相机的视角矩阵
            previousViewProjectionMatrix = cameraProjectMatirx * cameraWorldToCameraMatirx;
        }

        protected void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                material.SetFloat("_BlurSize", blurSize);

                material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);

                //得到当前的视图&&投影矩阵
                Matrix4x4 currentViewProjectionMatrix = cameraProjectMatirx * cameraWorldToCameraMatirx;
                //得到当前的视图&&投影矩阵的逆矩阵
                Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
                material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
                previousViewProjectionMatrix = currentViewProjectionMatrix;

                Graphics.Blit(src, dest, material);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}
