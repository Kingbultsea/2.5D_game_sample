Shader "Custom/BeHitShader"
{
    Properties
    {
        // 主纹理
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        // _Color("Add Color", Color) = (1,1,1,1)
        _Whiteness("Whiteness", Range(0, 1)) = 0.0
    }
    SubShader
    {
        // IGNOREPROJECTOR 是否应该忽略场景中的投影器
        // RenderType  用于标记Shader的渲染类型 这可以帮助Unity在需要处理透明对象时识别并应用适当的渲染技术。
        Tags { "QUEUE" = "Transparent" "IGNOREPROJECTOR" = "true" "RenderType" = "Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        // Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                half4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                half4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            fixed4 _Color;
            float _Whiteness; // 控制白化程度

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_TARGET
            {
                fixed4 tex = tex2D(_BaseMap, i.uv);
                // 使用lerp在原色和白色之间插值
                tex.rgb = lerp(tex.rgb, 1.0, _Whiteness);
                return tex;
            }
            ENDCG
        }
    }
}
