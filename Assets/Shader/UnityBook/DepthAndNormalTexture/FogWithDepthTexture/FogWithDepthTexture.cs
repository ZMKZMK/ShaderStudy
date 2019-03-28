using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class FogWithDepthTexture : PostEffectsBase
    {
        [SerializeField]
        private Shader fogShader;

        [SerializeField]
        private Material fogMaterial = null;
        public Material material
        {
            get
            {
                fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
                return fogMaterial;
            }
        }

        [SerializeField]
        private Camera myCamera;
        public Camera camera
        {
            get
            {
                if (myCamera == null)
                    myCamera = GetComponent<Camera>();
                return myCamera;
            }
        }

        [SerializeField]
        private Transform myCameraTransform;
        public Transform cameraTransform
        {
            get
            {
                if (myCameraTransform == null)
                    myCameraTransform = camera.transform;
                return myCameraTransform;
            }
        }

        [SerializeField, Range(0.0f, 3.0f),Header("雾效浓度系数：")]
        private float fogDensity = 1.0f;

        [SerializeField, Header("雾效颜色：")]
        private Color fogColor = Color.white;

        [SerializeField, Header("雾效起始高度：")]
        private float fogStart = 0.0f;
        [SerializeField, Header("雾效终止高度：")]
        private float fogEnd = 2.0f;

        void OnEnable()
        {
            camera.depthTextureMode |= DepthTextureMode.Depth;
        }

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                //近裁剪平截面的四角对应向量
                Matrix4x4 frustumCorners = Matrix4x4.identity;
            //FieldOfView | 近裁剪平面的距离 | 屏幕宽高比
                float fov = camera.fieldOfView;
                float near = camera.nearClipPlane;
                float aspect = camera.aspect;
                
                //近裁剪平面的一半高度 || 位于近裁剪平面的二维中心，指向相机正上方 && 指向相机正右方
                float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
                Vector3 toRight = cameraTransform.right * halfHeight * aspect;
                Vector3 toTop = cameraTransform.up * halfHeight;

                //近平面左上角的向量（相机到左上角的方向 + 距离）
                Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
                //右上角
                Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
                //左下角
                Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
                //右下角
                Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;

                //topLeft.magnitude = topRight.magnitude = bottomLeft.magnitude = bottomRight.magnitude
                float scale = topLeft.magnitude / near;

                // A点位于topLeft向量上
                // 相机到A点的距离 = (|topLeft|/Near) * depth(A)【相似三角形】
                // RayXXXXXX = (topLeft/|topLeft|)×(|topLeft|/Near)
                // 相机到A点的向量 = RayXXXXXX * depth(A) 【相机到A点的向量 = topLeft的方向(A的方向) × 相机到A点的距离】
                Vector3 RayTopLeft = topLeft.normalized * scale;
                Vector3 RayTopRight = topRight.normalized * scale;
                Vector3 RayBottomLeft = bottomLeft.normalized * scale;
                Vector3 RayBottomRight = bottomRight.normalized * scale;
               
                frustumCorners.SetRow(0, RayBottomLeft);
                frustumCorners.SetRow(1, RayBottomRight);
                frustumCorners.SetRow(2, RayTopRight);
                frustumCorners.SetRow(3, RayTopLeft);

                material.SetMatrix("_FrustumCornersRay", frustumCorners);

                material.SetFloat("_FogDensity", fogDensity);
                material.SetColor("_FogColor", fogColor);
                material.SetFloat("_FogStart", fogStart);
                material.SetFloat("_FogEnd", fogEnd);

                Graphics.Blit(src, dest, material);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}