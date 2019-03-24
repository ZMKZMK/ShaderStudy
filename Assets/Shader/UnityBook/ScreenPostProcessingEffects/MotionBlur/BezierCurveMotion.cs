using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ming
{
    public class BezierCurveMotion : MonoBehaviour
    {
        [SerializeField]
        private Transform _motionTrans;
        [SerializeField]
        private float _motionSpeed = 100;
        [SerializeField]
        private float _rotateSpeed = 100;
        [SerializeField,Range(0,5)]
        private float _bezierTSpeed = 1;
        [SerializeField]
        private Transform[] _bezierCurvePos;

        //贝塞尔 参数T
        private float _bezierT = 0;
        //贝塞尔 结果
        private Vector3 _bezierResult = Vector3.zero;

        protected void Update()
        {
            MoveTrans();
            RotateTrans();
        }

        protected void LateUpdate()
        {
            _motionTrans.position = Vector3.Slerp(
                _motionTrans.position,
                _bezierResult,
                Time.deltaTime * _motionSpeed
            );
            _motionTrans.position.Set(_motionTrans.position.x, _motionTrans.position.y, 0);
        }

        //实时运动，时间time作为贝塞尔参数t
        private void MoveTrans()
        {
            _bezierT = (_bezierT + Time.deltaTime * _bezierTSpeed) >= 1.0f ? 0.0f : _bezierT + Time.deltaTime * _bezierTSpeed;
            _bezierResult = GetBezierDestinationPosResult(_bezierT);
        }

        //贝塞尔曲线运动核心
        private bool tempCheckToBackPath = false;
        private Vector3 GetBezierDestinationPosResult(float t)
        {
            //走到尽头，往回走
            if (Math.Abs(t) <= 0.000001f)
            {
                tempCheckToBackPath = !tempCheckToBackPath;
            }

            int n = _bezierCurvePos.Length - 1;
            Vector3 result = Vector3.zero;

            if (!tempCheckToBackPath)
            {
                for (int i = 0; i < _bezierCurvePos.Length; ++i)
                    result += C(n, i) * _bezierCurvePos[i].position * Mathf.Pow(t, i) * Mathf.Pow(1.0f - t, n - i);
            }
            else
            {
                for (int i = _bezierCurvePos.Length - 1; i >= 0; --i)
                    result += C(n, n - i) * _bezierCurvePos[i].position * Mathf.Pow(t, n - i) * Mathf.Pow(1.0f - t, i);
            }
            return result;
        }

        //组合
        private long C(int n, int m)
        {
            int i;
            m = m < n - m ? m : n - m;
            long sum = 1;
            for (i = 1; i <= m; i++)
            {
                sum = (sum * (n - i + 1)) / i;
            }
            return sum;
        }

        //自转
        private void RotateTrans()
        {
            Quaternion forwardDirection = Quaternion.LookRotation(_bezierResult - _motionTrans.position);
            _motionTrans.localRotation = Quaternion.Euler(
                forwardDirection.eulerAngles.x,
                forwardDirection.eulerAngles.y,
                _motionTrans.localEulerAngles.z);
            float angle = Time.deltaTime * _rotateSpeed;
            _motionTrans.localRotation = Quaternion.Euler(
                _motionTrans.localRotation.eulerAngles.x,
                _motionTrans.localRotation.eulerAngles.y,
                _motionTrans.localRotation.eulerAngles.z + angle);
            /*_motionTrans.Rotate(
                Vector3.forward, 
                angle, 
                Space.Self
            );*/
        }
    }
}
