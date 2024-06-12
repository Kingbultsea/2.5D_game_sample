/* 测试情况用 */

using UnityEngine;

public class SyncSprite : MonoBehaviour
{
    private SpriteRenderer ShadowSpriteRenderer;
    private SpriteRenderer spriteRenderer;

    void Awake()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();

        // 获取CastShadow子对象
        var CastShadow = transform.Find("CastShadow").gameObject;
        // 反转 CastShadow 子游戏对象
        ShadowSpriteRenderer = CastShadow.GetComponent<SpriteRenderer>();
    }

    void LateUpdate()
    {
        // 同步 ShadowSpriteRenderer 的 sprite
        if (spriteRenderer.sprite != ShadowSpriteRenderer.sprite)
        {
            ShadowSpriteRenderer.sprite = spriteRenderer.sprite;
        }
        FlipCastShadow(spriteRenderer.flipX);
    }

    void FlipCastShadow(bool flip)
    {
        if (ShadowSpriteRenderer != null)
        {
            ShadowSpriteRenderer.flipX = flip;
        }
    }
}