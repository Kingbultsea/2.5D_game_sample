Shader "Custom/2DShadowShader"
{
    Properties
    {
        _PlayerTex ("Player Texture", 2D) = "white" {}
        _MainTex("Main Texture", 2D) = "white" {}
        _ShadowColor ("Shadow Color", Color) = (255,255,255,0.7)
        _UVRect ("UV Rect", Vector) = (0, 0, 1, 1) // 新增属性，用于传递UV坐标

        // 1f or 0f;
        // _FlipX ("Flip X", Float) = 0.0 // 新增属性，用于传递 flipX 状态
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }

        Cull Off 
        // 关闭深度写入，以确保透明对象正确混合和排序。
        // 透明对象通常不写入深度缓冲区，因为这可能导致后续渲染的对象被错误地遮挡。
        ZWrite Off 
        ZTest Always

        // FinalColor=(SourceColor×SrcFactor)+(DestinationColor×DstFactor)
        // FinalColor=((1,0,0,0.5)×0.5)+((0,0,1,1)×0.5)
        // FinalColor=(0.5,0,0,0.25)+(0,0,0.5,0.5)
        // FinalColor=(0.5,0,0.5,0.75)
        // 这种混合方式可以实现平滑的透明过渡效果，非常适合用于处理透明对象，如玻璃、半透明的UI元素等
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            // 获取模板缓冲区的当前值（Stencils[x, y]）。
            // 比较模板缓冲区的值和参考值（Ref）。
            // 根据比较结果和设置的操作，决定如何修改模板缓冲区的值和是否绘制该像素。
            Stencil {
                // 参考值，所有stencil，第一个物体，第一次渲染都要一个值做参考
                // 初始值是0
                // 这里只有第一次渲染会通过，通过才会被绘制，后续的都是fail，不会被渲染，因为不equal
                Ref 0
                Comp Equal
                Pass IncrSat 
                Fail IncrSat 
            }

            // CG/HLSL
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _PlayerTex;
            fixed4 _ShadowColor; // 阴影颜色和透明度
            float4 _UVRect; // 新增的UV矩形
            float _FlipX; // flipX 状态

            // 顶点着色器处理每个顶点的数据，并将结果传递给片段着色器。
            // struct appdata
            // {
            //     float4 vertex : POSITION; // 顶点位置
            //     float2 uv : TEXCOORD0;    // UV坐标
            // };
            v2f vert (appdata v)
            {
                v2f o;

                // UnityObjectToClipPos 是Unity内置函数，将对象空间中的顶点位置转换为裁剪空间中的位置。
                // 裁剪空间是顶点在投影和视口变换后的坐标空间，适用于图形管线后续的裁剪和光栅化步骤。
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.uv = TRANSFORM_TEX(v.uv, _PlayerTex);

                // if (_FlipX > 0.5)
                // {
                //     o.uv.x = 1.0 - o.uv.x; // 翻转 X 方向的 UV 坐标
                // }

                // 由于纹理坐标的原点通常在左下角，而Unity的纹理坐标原点在左上角，
                // 这里将Y轴坐标进行翻转，以适应纹理坐标系。
                o.uv.y = 1 - o.uv.y; // Y轴翻转
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 使用UV矩形采样正确的子纹理
                float2 uv = lerp(_UVRect.xy, _UVRect.zw, i.uv);
                fixed4 col = tex2D(_PlayerTex, uv);

                // return col;

                // 应用阴影颜色和透明度
                if (col.a > 0.1)
                {
                    // return col;
                    return _ShadowColor;
                }

                discard; // 丢弃透明部分
                return fixed4(0, 0, 0, 0); // 确保所有路径都有返回值
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
