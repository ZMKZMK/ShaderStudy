using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class MotionBlurAlone : MonoBehaviour
    {
        [SerializeField]
        private Shader motionBlurShader;
        [SerializeField]
        private Material motionBlurMaterial = null;
        [SerializeField,Header("动态对象:")]
        private Transform[] motionBlurTrans;
        private Vector3[] motionBlurTransLastPos;

        [SerializeField, Range(0.0f, 1.0f), Header("模糊系数(模糊采样距离)")]
        private float blurSize = 0.5f;

        public Material material
        {
            get
            {
                motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
                return motionBlurMaterial;
            }
        }

        protected void Start()
        {
            //为每个运动模糊对象增加一个材质
            motionBlurTransLastPos = new Vector3[motionBlurTrans.Length];
            for (int index = 0; index < motionBlurTrans.Length; ++index)
            {
                motionBlurTransLastPos[index] = motionBlurTrans[index].position;
                //------------
                Renderer renderer = motionBlurTrans[index].GetComponent<Renderer>();
                //---
                Material[] newMaterials = new Material[renderer.materials.Length + 1];
                for(int i = 0; i < renderer.materials.Length; ++i)
                {
                    newMaterials[i] = renderer.materials[i];
                };
                newMaterials[renderer.materials.Length] = material;
                //---
                renderer.materials = newMaterials;
            }

            StartCoroutine("SetSpeedVector");
        }

        protected void OnDestroy()
        {
            Destroy(material);
            StopAllCoroutines();
        }

        IEnumerator SetSpeedVector()
        {
            var wfs = new WaitForSeconds(0.05f);
            while (true)
            {
                yield return wfs;
                DoSetSpeedVector();
            }
        }
        private void DoSetSpeedVector()
        {
            for (int index = 0; index < motionBlurTrans.Length; ++index)
            {
                Vector3 speedInWorld = motionBlurTrans[index].position - motionBlurTransLastPos[index];
                int lastIndex = motionBlurTrans[index].GetComponent<Renderer>().materials.Length - 1;
                motionBlurTrans[index].GetComponent<Renderer>().materials[lastIndex].SetVector(
                    "speedVector",
                    speedInWorld
                );
            }
            UpdateLastBlurMotion();
        }

        private void UpdateLastBlurMotion()
        {
            for (int index = 0; index < motionBlurTransLastPos.Length; ++index)
                motionBlurTransLastPos[index] = motionBlurTrans[index].position;
        }

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
                material.hideFlags = HideFlags.DontSave;
                if (material)
                    return material;
                else
                    return null;
            }
        }
    }
}