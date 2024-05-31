using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class CameraControl : MonoBehaviour
{
    public float moveSpeed = 10f; // 摄像机移动速度
    public Vector2 inputVec;

    void Update()
    {
        MoveCamera();
    }

    void OnMoveR(InputValue value)
    {
        inputVec = value.Get<Vector2>();
    }

    void MoveCamera()
    {
        // 获取当前摄像机的位置
        Vector3 currentPosition = transform.position;
        
        // 计算移动量
        Vector3 movement = new Vector3(inputVec.x, inputVec.y, 0) * moveSpeed * Time.deltaTime;
        
        // 更新摄像机的位置
        transform.position = currentPosition + movement;
    }
}
