using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.PlayerLoop;

public class RenderCubeMapInRuntime : MonoBehaviour
{
    [SerializeField]
    private Camera camera;
    [SerializeField]
    private Transform renderFromPosition;
    [SerializeField]
    private Cubemap cubemap;

    void Update()
    {
        renderCubeMap();
    }

    void renderCubeMap()
    {
        if (camera.transform.position != renderFromPosition.position)
        {
            camera.cullingMask &= ~(1 << 8); // 关闭层x  
            camera.transform.position = renderFromPosition.position;
            camera.RenderToCubemap(cubemap);
            camera.cullingMask |= (1 << 8);  // 打开层x  
        }
    }
}
