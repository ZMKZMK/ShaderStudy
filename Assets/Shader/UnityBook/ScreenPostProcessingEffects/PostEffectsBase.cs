using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace Ming
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class PostEffectsBase : MonoBehaviour
    {
        private Material material = null;

        #region Mono
        protected void Awake()
        {
            CheckResources();
        }

        protected void OnDestroy()
        {
            if (material != null)
                DestroyImmediate(material);
        }
        #endregion

        #region Check
        // Called when start
        // 检查资源和条件是否满足
        protected void CheckResources()
        {
            bool isSupported = CheckSupport();

            if (isSupported == false)
            {
                NotSupported();
            }
        }

        // Called in CheckResources to check support on this platform
        // 检测系统是否支持屏幕后处理特效 以及 RT
        protected bool CheckSupport()
        {
            if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
            {
                Debug.LogWarning("This platform does not support image effects or render textures.");
                return false;
            }

            return true;
        }

        // Called when the platform doesn't support this effect
        protected void NotSupported()
        {
            this.enabled = false;
        }

        #endregion

        // Called when need to create the material used by this effect
        protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
        {
            if (shader == null)
            {
                return null;
            }

            if (shader.isSupported && material && material.shader == shader)
                return material;

            if (!shader.isSupported)
            {
                return null;
            }
            else
            {
                material = new Material(shader);
                this.material = material;
                material.hideFlags = HideFlags.DontSave;
                if (material)
                    return material;
                else
                    return null;
            }
        }
    }
}
