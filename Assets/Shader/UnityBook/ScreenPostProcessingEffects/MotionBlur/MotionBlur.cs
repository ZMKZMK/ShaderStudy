using System.Collections;
using System.Collections.Generic;
using System.Runtime.Remoting.Messaging;
using UnityEngine;

namespace Ming
{
    public class MotionBlur : PostEffectsBase
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

        [Range(0.0f, 1f), Header("运动模糊拖尾效果(越大，之前帧的图像暂存的越久，即之前帧的混合比例会更大)：")]
        public float blurAmount = 0.5f;

        [SerializeField,Header("累计 RT buffer")]
        private RenderTexture accumulationTexture;

        void OnDisable()
        {
            //DestroyImmediate(accumulationTexture);
        }

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (material != null)
            {
                // Create the accumulation texture
                if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
                {
                    DestroyImmediate(accumulationTexture);
                    accumulationTexture = new RenderTexture(src.width, src.height, 0);
                    accumulationTexture.hideFlags = HideFlags.NotEditable;
                    Graphics.Blit(src, accumulationTexture);
                }

                // We are accumulating motion over frames without clear/discard
                // by design, so silence any performance warnings from Unity
                // 标记当前RT为不清除状态，可以关闭掉unity的警告
                //accumulationTexture.MarkRestoreExpected();

                material.SetFloat("_BlurAmount", 1.0f - blurAmount);

                Graphics.Blit(src, accumulationTexture, material);
                Graphics.Blit(accumulationTexture, dest);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}
