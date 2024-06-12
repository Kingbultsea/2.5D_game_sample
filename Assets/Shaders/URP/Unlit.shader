// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Universal Render Pipeline/Unlit"
{
    Properties
    {
        // [optional: attribute] name("display text in Inspector", type name) = default value

        // 主纹理
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        // 主色
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)

        // 控制surface options/ threshold 区间值
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5

        // BlendMode
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0

        _Whiteness("Whiteness", Range(0, 1)) = 0.0

        // 复选框
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        [HideInInspector] _AddPrecomputedVelocity("_AddPrecomputedVelocity", Float) = 0.0

        // Editmode props
        _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
        [HideInInspector] _SampleGI("SampleGI", float) = 0.0 // needed from bakedlit
    }

    SubShader
    {
        // https://docs.unity3d.com/Manual/SL-SubShaderTags.html
        Tags
        {
            // 选择什么类型的着色器 标记不透明的材质。不透明材质不会进行透明度混合，通常在渲染队列的前面被渲染。
            "RenderType" = "Opaque"
            // 投影效果
            "IgnoreProjector" = "False"
            "UniversalMaterialType" = "Unlit"
            // 告诉unity 选择什么样的管线 如使用HDRP就设置为 HDRenderPipeline 如果不声明就是两者都不适用
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        // -------------------------------------
        // Render State Commands
        // 如果使用默认值的话，就是Blend SrcAlpha OneMinusSrcAlpha
        Blend [_SrcBlend][_DstBlend], SrcAlpha OneMinusSrcAlpha
        ZWrite On
        Cull Off

        Pass
        {
            // Tags { "QUEUE" = "Transparent" "IGNOREPROJECTOR" = "true" "RenderType" = "Transparent"}
            // ZWrite On
            // Blend SrcAlpha OneMinusSrcAlpha
            // LOD 100
            // Cull Off
         
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
            // float4 _BaseMap_ST;
            fixed4 _Color;
            float _Whiteness; // 控制白化程度
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 自动处理平铺和偏移，需要float4 _BaseMap_ST;自动传递
                // o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv = v.texcoord;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_TARGET
            {
                fixed4 tex = tex2D(_BaseMap, i.uv);
                if (tex.a > 0.1)
                {
                  // 使用lerp在原色和白色之间插值
                  tex.rgb = lerp(tex.rgb, 1.0, _Whiteness);
                  return tex;
                }

                // discard 关键字用于在片段着色器中丢弃当前片段（像素），即不渲染当前片段
                // 使其不进行进一步的颜色写入或深度写入操作。这对于实现某些效果，例如剪切透明像素，十分有用
                discard;

                // 在HLSL中，片段着色器必须保证所有的执行路径都有一个明确的返回值
                return fixed4(0, 0, 0, 0); // 确保所有路径都有返回值（类型问题）
            }
            ENDCG
        }

        // 每个 SubShader 可以包含一个或多个 Pass，每个 Pass 代表一个渲染操作，比如绘制一次物体
        Pass
        {
            Name "Unlit"

            // -------------------------------------
            // Render State Commands
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitForwardPass.hlsl"
            ENDHLSL
        }

        // Fill GBuffer data to prevent "holes", just in case someone wants to reuse GBuffer for non-lighting effects.
        // Deferred lighting is stenciled out.
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "UnlitInput.hlsl"
            #include "DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // -------------------------------------
            // Render State Commands
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            // -------------------------------------
            // Unity defined keywords
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "UnlitInput.hlsl"
            #include "UnlitMetaPass.hlsl"
            ENDHLSL
        }

        // Pass
        // {
        //     Name "MotionVectors"
        //     Tags { "LightMode" = "MotionVectors" }
        //     ColorMask RG

        //     HLSLPROGRAM
        //     #pragma shader_feature_local _ALPHATEST_ON
        //     #pragma multi_compile _ LOD_FADE_CROSSFADE
        //     #pragma shader_feature_local_vertex _ADD_PRECOMPUTED_VELOCITY

        //     #include "UnlitInput.hlsl"
        //     #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ObjectMotionVectors.hlsl"
        //     ENDHLSL
        // }

        // Pass
        // {
        //     Name "HitAnimation"
        //     // Tags { "QUEUE" = "Transparent" "IGNOREPROJECTOR" = "true" "RenderType" = "Transparent"}
        //     // ZWrite On
        //     // Blend SrcAlpha OneMinusSrcAlpha
        //     // Cull Off
            
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "UnityCG.cginc"
        //     struct appdata
        //     {
        //         half4 vertex : POSITION;
        //         float2 texcoord : TEXCOORD0;
        //         fixed4 color : COLOR;
        //     };
        //     struct v2f
        //     {
        //         half4 pos : SV_POSITION;
        //         float2 uv : TEXCOORD0;
        //         fixed4 color : COLOR;
        //     };
        //     sampler2D _BaseMap;
        //     float4 _BaseMap_ST;
        //     fixed4 _Color;
        //     float _Whiteness; // 控制白化程度
        //     v2f vert (appdata v)
        //     {
        //         v2f o;
		// 		o.pos = UnityObjectToClipPos(v.vertex);
		// 		return o;
                
        //         v2f o;
        //         o.pos = UnityObjectToClipPos(v.vertex);
        //         o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
        //         o.color = v.color;
        //         return o;
        //     }
        //     fixed4 frag (v2f i) : SV_TARGET
        //     {
        //         return fixed4(0,0,1,1);
        //         fixed4 tex = tex2D(_BaseMap, i.uv);
        //         // 使用lerp在原色和白色之间插值
        //         tex.rgb = lerp(tex.rgb, 1.0, 0.2);
        //         return tex;
        //     }
        //     ENDCG
        // }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.UnlitShader"
}
