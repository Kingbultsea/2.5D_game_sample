using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraControl : MonoBehaviour
{
    public float moveSpeed = 10f; // 摄像机移动速度

    void Update()
    {
        // 获取输入
        float moveX = Input.GetAxis("Horizontal"); // A和D键控制水平移动
        float moveY = Input.GetAxis("Vertical");   // W和S键控制垂直移动

        // 计算移动方向
        Vector3 move = new Vector3(moveX, moveY, 0);

        // 移动摄像机
        transform.position += move * moveSpeed * Time.deltaTime;
    }
}
