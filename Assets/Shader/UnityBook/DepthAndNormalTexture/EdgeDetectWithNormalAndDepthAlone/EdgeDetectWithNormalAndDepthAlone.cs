using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class EdgeDetectWithNormalAndDepthAlone : PostEffectsBase
    {
        [SerializeField]
        private Transform[] OutLineTrans;
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
        [SerializeField, Range(0.0f, 1.0f)]
        protected float edgesOnly = 0.0f;
        [SerializeField]
        protected Color edgeColor = Color.black;
        [SerializeField]
        protected Color backgroundColor = Color.white;
        [SerializeField]
        protected float sampleDistance = 1.0f;
        [SerializeField]
        protected float sensitivityDepth = 1.0f;
        [SerializeField]
        protected float sensitivityNormals = 1.0f;
        //OnRenderImage()会在所有不透明和透明的Pass执行完后再进行调用
        //使用[ImageEffectOpaque]属性，可以在不透明的Pass(queue<=2500)执行后立刻调用
        protected void Update()
        {
            if (material != null)
            {
                material.SetFloat("_EdgeOnly", edgesOnly);
                material.SetColor("_EdgeColor", edgeColor);
                material.SetColor("_BackgroundColor", backgroundColor);
                material.SetFloat("_SampleDistance", sampleDistance);
                material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

                foreach (Transform tran in OutLineTrans)
                {
                    Graphics.DrawMesh(
                        tran.GetComponent<MeshFilter>().sharedMesh,
                        tran.position - new Vector3(1,1,1),
                        tran.rotation,
                        material,
                        0,
                        GetComponent<Camera>());

                }
            }
        }

    }
}
