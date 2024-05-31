using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.OnScreen;
using UnityEngine.UI;

public class JoyStickShower : OnScreenStick, IPointerDownHandler, IPointerUpHandler, IDragHandler
{
    [SerializeField] private Image JoyStick;
    private bool isTouching = false;
    private int touchId = -1;
    private Vector2 originPosition;

    public void OnPointerDown(PointerEventData eventData)
    {
        if (!isTouching)
        {
            isTouching = true;
            touchId = eventData.pointerId;

            RectTransform joyStickRectTransform = JoyStick.GetComponent<RectTransform>();

            if (originPosition == Vector2.zero)
            {
                originPosition = joyStickRectTransform.anchoredPosition;
            }

            // 设置非透明
            // JoyStick.color = new Color(JoyStick.color.r, JoyStick.color.g, JoyStick.color.b, 1);

            // 转换屏幕坐标到世界坐标
            Vector2 localPoint;
            RectTransform canvasRectTransform = JoyStick.canvas.GetComponent<RectTransform>();
            RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasRectTransform, eventData.position, eventData.pressEventCamera, out localPoint);

            // Debug.Log($"鼠标位置{eventData.position} 转换后的位置{localPoint} 初始位置{originPosition}");

            // 设置 JoyStick 的本地位置
            joyStickRectTransform.anchoredPosition = localPoint;

            base.OnPointerDown(eventData);

            // JoyStick.transform.position = eventData.position;
        }

    }

    public void OnDrag(PointerEventData eventData)
    {
        if (eventData.pointerId == touchId)
        {
            // 处理摇杆拖动逻辑
            // Vector2 joystickPosition = eventData.position;
            // 实现摇杆逻辑

            base.OnDrag(eventData);
        }
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        if (eventData.pointerId == touchId)
        {
            isTouching = false;
            touchId = -1;

            base.OnPointerUp(eventData);

            // 设置透明
            // JoyStick.color = new Color(JoyStick.color.r, JoyStick.color.g, JoyStick.color.b, 0);

            // 设置回手指原点
            if (originPosition != Vector2.zero)
            {
                RectTransform joyStickRectTransform = JoyStick.GetComponent<RectTransform>();
                joyStickRectTransform.anchoredPosition = originPosition;
            }
        }
    }
}
